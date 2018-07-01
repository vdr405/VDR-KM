*************************************************************************
*             CLIENT:  
*           PROTOCOL:   
*       PROGRAM NAME:  AE Table
*        SAS VERSION:  SAS V9.2 and above
*            PURPOSE:  Generate AE SOC by PT Tables
*
*             AUTHOR:  KAVITHA MULLELA
*       DATE CREATED:  
*************************************************************************

*** cleaning log and work lib;
%include "MMACRO.sas";
*** cleaning log and work lib;
%blank(); 

/**** Assign Treatment variable here ****/
%let TMTN= %str(trt01an);
%let TMTC=%str(TRT01a);

/***** Format for new treatment Sub Groups ****/
proc format;
value trtx
 77= "Group 1"
 78= "Group 2"
 79= "Group 3"
 99= "Total";
run;

/**** Copy ADSL to Work Lib ***/
Proc copy in=derived out=work;
select ADSL ADAE;
run;
 
/*** ADD Dummy Treatments to ADSL - Do not apply any subset***/
%dummy_trt(in= adsl, out=POPSET, dummytrts=  (1 2) ~ 77! 
											(3 4) ~ 78! 
											(5 6) ~ 79!
											(1 2 3 4 5 6) ~ 99);



*** to get list of cohorts in the study;
%getarms(in=POPSET);

*** Get BigN counts for Header and Percentage Counts. Applying Population Subset here;
%getbign(in=POPSET ,countvar= USUBJID, trtvar= &TMTC, where= (strip(SAFFL) eq "Y") );

/***** Bringing in Table Data. ***/
Data ADAE;
 set ADAE;
 where SAFFL eq "Y" and TRTEMFL eq "Y" and AETERM ne "";
run;

/*** ADD Dummy Treatments to ADAE ***/
%dummy_trt(in= adae, out=AESET, dummytrts=  (1 2) ~ 77! 
											(3 4) ~ 78! 
											(5 6) ~ 79!
											(1 2 3 4 5 6) ~ 99);


 %macro tab( out= , where= , whr=  ,  AESOC= ,miss1= , AEPT= ,miss2= , AEPT2= , srt= ,line1= ,line2= ,perc= );
   
 * check for Zero obs;
 %onoff(dsin=adae);
  
 %if &numobs =0 %then %do;
   data report; 
   		txt= "There are no observations to report for this Table";
  	 run;	
 %end;

 %else %do;
 
data adae2;
length &aesoc &aept &AEPT2 $1000;
 set aeset;
  if missing(&aesoc) then &AESOC= "&miss1";
  if missing(&aept) and "&miss2" ^= " "  then &AEPT=strip("&miss2")||"*";
   else if missing(&aept2) and missing("&miss2") and not missing(&AEPT2) then &AEPT= strip(&AEPT2)||"*";
   stxt= strip(&AEPT);   
 run;

proc sql noprint;
	create table overall as select &TMTC,2 as ord,"&line2" as txt,
					count( distinct Usubjid) as count from adae2 group by &TMTC,txt, ord;
	create table events as select &TMTC, 1 as ord,"&line1" as txt, count(usubjid) as count from adae2 group by &TMTC,txt,ord;
	create table soc as select &TMTC,3 as ord,&aesoc, count(distinct usubjid) as count from adae2 group by &TMTC,&aesoc,ord; 	
	*create table pt as select &TMTC, &aesoc, &aept, count(distinct usubjid) as count from adae2 group by &TMTC,&aesoc,&aept; 
quit;

proc sort data= adae2 out=pt nodupkey; by &TMTC &aesoc &aept usubjid; run;

proc freq data=pt noprint;
 table &TMTC*&aesoc*&aept/out=pt(drop= percent);
run;

%macro count(in= , out= , by= , lst= , by2= );
		
	proc sort data= &in; by &by2; run;

	proc transpose data= &in out=t&out;
		 by &by2;
		 id &TMTC;
		 var count;
	run;

   data &out; 
	 set t&out;
	 %if "&in" ^= "events" %then %do;
		%align(old= &armlis,new=&nname, BigN=arm);
  	%end;
	%else %do;
	 array a[*] &armlis;
	 array b[&Narm] $50 &nname;
	  do i=1 to &Narm;
	   if a[i] eq . then b[i]= put(0,6.);
	   if a[i] ne . then b[i]= "  "||put(a[i],8.);	   
	  end;
	%end;
	run;

	%if (&in = pt) and (&perc= Y) %then %do;
		data &out;
		 set &out;
		 if perc <10  then delete;
		run;

		proc sort data= &out out=d&out (keep= &aesoc) nodupkey; by &aesoc; run;
	%end;

%mend;
** EVENTS;
%count(in=events, out=event2,by2=%str(txt));
** OVERALL COUNTS;
%count(in=overall, out=line2,by2=%str(txt));
** SOC COUNTS;
%count(in=soc, out=soc2, by2= %str(&AESOC )); 
** PT COUNTS;
%count(in=pt, out=pt2, by2= %str(&AESOC &AEPT));

%if &perc = Y %then %do;
data soc2;
 merge soc2(in=a) dpt2(in=b);
  by &AESOC;
  if a and ^b /*and perc <10*/  then delete;
 run;
%end;

**** determine sort order, either Ascending or Descending; 
	%if %index(%upcase(&srt),DESCENDING) > 0 %then %let srt_type= %str(descending);
	%else %let srt_type= ;

  *** FOR ALPHABETICAL SORT;
  %if %index(%upcase(&srt), ALPHA) >0 %then %do;	
  
   proc sort data= soc2; by &AESOC ; run;
   proc sort data= pt2; by &srt_type total &AESOC &AEPT; run;
   
   data socord(keep=&AESOC socord);  
	set soc2;
	 	socord= _n_;
    by &AESOC;   
    run;

   data ptord(keep= &AESOC &AEPT ptord);
	set pt2;
    	ptord= _n_;
	 by  &srt_type total &AESOC &AEPT;
	run;
  %end;
  
  *** FOR FREQUENCY SORT;
 %if %index(%upcase(&srt),FREQ) > 0 %then %do;

   proc sort data= soc2; by  &srt_type total &AESOC ; run;
   proc sort data= pt2; by  &srt_type total &AESOC &AEPT; run;
	 
   data socord(keep= &AESOC  socord);
    set soc2;
	socord=_n_;
   by  &srt_type total &AESOC ;
   run;

   data ptord(keep=&AESOC &AEPT ptord); 
   set pt2;
    ptord=_n_;
   by &srt_type total &AESOC &AEPT;
   run;

 %end;

 proc sort data= socord; by &AESOC ; run;
 proc sort data= ptord; by &AESOC &AEPT; run;

***SETTIING all counts to gether;
* to merge the sorting order back to the original datasets;

%macro ord(in= , ord= , val= ); 

	proc sort data= &in; by &val; run;

	data &in;
 	 merge &in &ord;
 	  by &val;
	run;

%mend;
%ord(in=soc2, ord= socord, val=%str(&AESOC)); * setting soc sorting sequence;
%ord(in=PT2, ord= SOCORD, val=%str(&AESOC));  *setting soc sorting sequence to pt;
%ord(in=PT2, ord= PTORD, val=%str(&AESOC &AEPT)); *setting pr sorting sequence to pt;

data all(drop=  _name_  );
length txt $500;
  set event2(in=a)
	  line2(in=b)
		soc2(in=c)
		 pt2(in=d);
 	if a then bl=1;
 	if b then bl=2;
 	if c or d then bl=3;  
 run;

data all2; 
 set all; 
 /*array a[*] &nname;
	do i=1 to dim(a);
		 if a[i] ne "" then a[i]= ""||a[i];
	 end;
 drop i;*/
  if bl >2 and txt eq "" then do;
    if &AESOC ne " " and &AEPT eq " " then txt= strip(&AESOC);
	 else txt= strip(&AEPT);
  	end;	
	pg=1;
 run;

proc sort data= all2 out=&out; by pg bl socord ptord; run;

%end;
%mend;

** calling Table parameters;
%tab(out= T05 ,                           /** final dset that goest to report **/      
      AESOC= aebodsys,                /** SOC_NAME/ATC2 information **/
      miss1= %str(UNCODED),      /** If by1 is missing then replace by1 with miss1 **/
      AEPT=aedecod ,               /** PT_NAME/PREFNAM information **/
      miss2= %str(),                  /** If by2 is missing then replace by2 with miss2 **/
      AEPT2=AETERM,              /** CONVT/MEDVT/AEVT information **/    
      srt=%str(FREQ DESCENDING), /* sorting order preference - enter 'ALPHA' for sorting to be done by alphabetical order 'FREQ' for desceding frequency order*/
      line1=%STR(Total Number of Treatment Related Adverse Events with a CTCAE Grade of 3 or 4), /** Number of Events Row**/      
	  line2= %str(Number of Subjects With at Least One Treatment Related Adverse Event with a CTCAE Grade of 3 or 4),   /** Number of Subjects Row**/     
       perc=N);  /*** maximum number of lines per page */
 
