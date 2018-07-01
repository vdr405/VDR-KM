************************************************************************
*       PROGRAM NAME: MACRO.sas
*	     SAS VERSION: V9.2	
*            PURPOSE: To use in table programs
*                    
 
*        INPUT FILES: 
*       OUTPUT FILES: 
*
*             AUTHOR: Kavitha Mullela
*************************************************************************

*<)  macro to clean log, output and work library (>;
%macro blank();
 *create a  dummy dset;
 data dummy;run;
 * clean log and output;
 dm "clear log" ; dm "clear output";
 *clean work lib;
 proc datasets lib=work memtype=data kill nolist;
 run;
 quit;
%mend;

*------- Macro to clean Temp datasets -------*;
%macro clean(save= ,delete= ,killall= );
    proc datasets memtype=data lib=work &killall nolist;
        %if &save ^= %then
            %do;
                save &save;
            %end;
        %else %if &delete ^= %then
            %do;
                delete &delete;
            %end;
   run;
   quit;
%mend;

/*** Check for number of obs ***/
%macro onoff(dsin=	);
	%global numobs exist;    
	*** Makesure dataset exist;
 	%let exist= %sysfunc(exist(&dsin));   
	*** If dataset exist, find number of obs;
	%if &exist>0 %then %do;
    	%let dsid= %Sysfunc(open(&dsin));
    	%let Numobs= %sysfunc(attrn(&dsid,nobs));
    	%let rc=%sysfunc(close(&dsid));    	
	%end;	
	%else %do;
		%let numobs= %str(0);
	%end;

	%put  "Number of obs in &dsin : &numobs";
%mend; 


** dummy trt macro;
%macro dummy_trt(in= ,out= ,dummytrts=  );

%let _dum= %sysfunc(countc(&dummytrts,'~'));
%put &_Dum;

%do i=1 %to &_dum;
 %let grp&i = %qscan(&dummytrts,&i,"!");
 %let tmt&i= %qscan(&&grp&i,1,"~");
 %let _tmt&i=%qscan(&&grp&i,2,"~");
 %put &&grp&i &&tmt&i &&_tmt&i;
 
data &out&i ; 
 	set &in;
  		if &TMTN in &&tmt&i ;
		&TMTN= &&_tmt&i.;	
		&TMTC=put(&TMTN,TRTX.);
run;

%end;

data &out;
 set &in %do k=1 %to &_Dum; &out&k %end;;
run;


%mend;
**** Sample call;
%*dummy_trt(in= adsl, out=POPSET, dummytrts=  (1 2) ~ 77! 
											(3 4) ~ 78! 
											(5 6) ~ 79!
											(1 2 3 4 5 6) ~ 99);



*<)----------------------- To get the Char list in the Header -----------------(>*;
*<)---- Use ADSL without any subset after Running %Dummy_TRT macro for ADSL ----(>*;
%macro getarms(in= );
proc sort data= &in out=cohort(keep=&TMTC ) nodupkey; by &TMTC; run;

%global arms Narms;
data cohort; 
 set cohort(where=(&TMTC ne "")) end=eos;
   length arms $500;
	retain arms;
	if _N_ eq 1then arms= compress(&TMTC);
	 else arms= strip(arms)||" "||compress(&TMTC);
	 if eos then call symput('arms',strip(arms));	
	 if eos then call symput('Narms',strip(put(_n_,best.)));
	 x=1;
	 by &TMTC;
run;
%put "Original Text value in Treatment Column:" &arms;
%put "Total number of Treatment Groups:" &Narms;


proc transpose data= cohort out=cohort1(drop= _name_ _label_);
id &TMTC;
var x;
run;

proc contents data= cohort1 out=cohortlis(keep=name libname) noprint;
run;

%global armlis Narm rname Nname;

data cohortlis;
	set cohortlis end=eos;
	length rname nname c $1000;
	retain rname nname c;
	*** for renaming purpose;
	Rcohort=strip(name)||"="||" __"||compress(name,"_");
	if first.libname then rname= strip(rcohort);
		else rname=strip(rname)||" "||strip(rcohort);
	if eos then call symput('rname',strip(rname));

	*** for Proc report column calling;
	Ncohort=scan(rcohort,2,"=");
	if first.libname then Nname= strip(ncohort);
		else nname=strip(nname)||" "||strip(ncohort);
	if eos then call symput('nname',strip(nname));

	*** for %align macro use;
	 if first.libname then  C=strip(name);
		else C= strip(C)||" "||strip(name);
		if eos then call symput('ARMLIS',strip(C));
		if eos then call symput('Narm',strip(put(_n_,best.)));
	
	by libname;
run;

%put	 "Original Treatment Columns:" &armlis ;
%put	 "Number of Treatment Groups:" &narm;
%put	 "Renaming sequencs:" &rname;
%put	 "New Final Treatment names:" &nname;

%mend;

*<) macro to calculate percentages and align them (>;
%macro align(old= ,new= , BigN= );	
	array cp[*] &old;
	array cpk[*] $50 &new;
    %do i=1 %to &Narm;  
    if cp[&i] eq . then cp[&i]= 0 ;
	   if &&&BigN&i gt 0 then cpk[&i] = put(cp[&i],6.)||" ("||put((cp[&i]/&&&BigN&i)*100,5.1)||"%)";
	   if cp[&i]> 0 and index(compress(cpk[&i]),'(0.0%)')> 0 then cpk[&i]= put(cp[&i],6.)||" ("||"<0.1"||"%)";
	   if cp[&i] eq 0 then cpk[&i] = "0";
	   if substr(compress(cpk[&i]),1,1) eq "0" then cpk[&i]= put(0,6.);
	   cpk[&i]= tranwrd(cpk[&i],"100.0%)", "100%)"); 
	   if cpk[&i] ne "" then cpk[&i]= "  "||cpk[&i];
	   *if &i eq &Narm and cp[&i] > 0 and &&&BigN&i> 0 then perc= round((cp[&i]/&&&BigN&i)*100,0.1);
	   *if &i > 4 then cpk[&i]= "   "||cpk[&i];	               
	  %end;  
%mend;

** Bign Counts;
%macro getbign(in= ,countvar= , trtvar= , where=  );

** Column BigN;
%do i=1 %to &Narms;
%global arm&i;
%let Tarm= %qscan(&arms,&i,' ');
%put &Tarm;
proc sql noprint;
	select count(distinct &countvar) into:arm&i from &in  where &where and compress(&trtvar) eq compress("&Tarm");
quit;
%let arm&i= %cmpres(&&arm&i);
%put &&arm&i;
%end;

*** Total column counts;
/*%global arm&Narm;*/
/*proc sql noprint;*/
/* select count(distinct &countvar) into: total from &in where &where;*/
/*quit;*/
/*%let arm&Narm= %cmpres(&total);*/
/*%put &&arm&Narm;*/
%mend;

** Text conversion;
%macro conv1(var= );
select(strip(lowcase(&var)));
	 when("nc") txt= "n";
	 when("meansdc") txt="Mean (SD)";
	 when("medc") txt= "Median";
	 when("minmax") txt= "Min, Max";
	 otherwise txt="";
   end;
%mend;


*** To get labels for Cohorts;
%macro getlabel(in);

proc sort data=&in out=label(keep=cohort where=(&TMTC ne "")) nodupkey; by &TMTC;run;

data label;
 set label end=eos;
 length cohort2 $50;
 if &TMTC ne "" then cohort2= compress(&TMTC); *scan(cohort,1,":")||":$"||strip(scan(cohort,2,":"));
 if first.&TMTC then I+1;
 by &TMTC;
 if eos then call symput('mx', put(i,best.));
 run;

%do i=1 %to &mx;
%global label&i Hlabel&i colhead1 colhead2 colhead3;

proc sql noprint;
	select strip(&TMTC) into: label&i from label where i eq &i;
	select strip(cohort2) into: Hlabel&i from label where i eq &i;
quit;
  %put &&label&i &&Hlabel&i;
%end;
 
%mend;
