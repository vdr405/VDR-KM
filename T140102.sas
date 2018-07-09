*************************************************************************
*             CLIENT: 
*           PROTOCOL:  
*       PROGRAM NAME:  T140102.sas
*        SAS VERSION:  SAS V9.1.3
*            PURPOSE:  
*
*        USAGE NOTES:  Batch Submit via PC SAS v9.1.3  
*        INPUT FILES:  adb.Header
*       OUTPUT FILES:  T140102.rtf & corresponding log file 
*
*             AUTHOR:  DINESH VIPPALA
*       DATE CREATED:  22MAR2012
*        

*   MODIFICATION LOG:   
*************************************************************************
* DATE          INITIALS        MODIFICATION DESCRIPTION
*************************************************************************
* DDMONYYYY                    Complete description of modification made
*                               including reference to source of change.
*
*************************************************************************
*  © 2011 Pharmaceutical Product Development, Inc.
*  All Rights Reserved.
*************************************************************************;
%include "MMACRO.sas";
*** cleaning log and work lib;
%clean();

proc sort data= adb.header out=header(where=(ITTFL eq "Y")); by cohort subject; run;

** to impute total column;
%dummy_trt(in=header);
** to get the list of cohorts in the study;
%getarms;

data header; 
	set header;
	if enroldt ne . then enrlfl= "Y";
run;

%macro tab;

 ** BiGn Counts;
 %getbign(in= adb.header, countvar=subject, trtvar=cohort ,where=(strip(ITTFL) eq "Y"));

 
 * check for Zero obs;
 %onoff(source= header);

 %if &numobs =0 %then %do;
 	 data report; 
   		txt= "There are no observations to report for this Table";
  	 run;

	 ODS RTF FILE=".\Output\T140102.rtf" STYLE=StyleA;
	ODS LISTING CLOSE;
	ODS escapechar = "~"; 
	%get_tf(TLF_PROGNAME=T140102,escapechar= ~);
	options nobyline;
	options nocenter;
	proc report data =report nowd 
         headline headskip split="$"  spacing=0 formchar(2)='_' missing; 

  	column  txt;
   define txt/ " " order style = [just=l cellwidth=99% asis = on];  
   	compute before txt;
     line "";
    endcomp;    

	run;
	ods rtf close;
	ods listing;
	*** call rtf_post to post process footer text and body wrapping ***;
	%rtf_post();

 %end;

 %else %do;
 ** getting counts for lines;
   proc sql noprint;
	create table enrol as select cohort,"All Enrolled Population" as txt, 1 as ord, count(distinct subject) as count from header where enrlfl eq "Y" group by cohort;
	create table itt as select cohort, "ITT Population" as txt, 2 as ord, count(distinct subject) as count from header where ittfl eq "Y" group by cohort;
	create table safe as select cohort, "Safety Population" as txt, 3 as ord, count(distinct subject) as count from header where saffl eq "Y" group by cohort;
	create table imm as select cohort, "Immunogenicity Population" as txt,4 as ord, count(distinct subject) as count from header where immfl eq "Y" group by cohort;
	create table pk as select cohort, "PK Population" as txt, 5 as ord, count(distinct subject) as count from header where pkfl eq "Y" group by cohort;
	create table line2 as select cohort,"Total Number of Subjects Discontinued Treatment" as txt,6 as ord,  count(distinct subject) as count from header 
																														where eotreas ne "" group by cohort;
	create table line3 as select cohort,eotreas as txt ,7 as ord, count(distinct subject) as count from header where ^(EOTREAS eq "AE" and deathfl eq "Y") and eotreas ne ""
					group by cohort,eotreas;
	create table FU as select cohort,"Number of Subjects Completing Follow-up" as txt ,8 as ord, count(distinct subject) as count from header where eotreas ^in 
					( "Lost to Follow-Up", "Withdrawal of consent", "Death", "Other" , "" ) group by cohort;	
	create table NFU as select cohort,"Number of Subjects not Completing Follow-up" as txt ,9 as ord, count(distinct subject) as count from header where eotreas in 
					( "Lost to Follow-Up", "Withdrawal of consent", "Death", "Other" ) group by cohort;	
   create table NFUREAS as select cohort,eotreas as txt ,11 as ord, count(distinct subject) as count from header where eotreas in 
					( "Lost to Follow-Up", "Withdrawal of consent", "Death", "Other" ) group by cohort,eotreas;		
   quit;


** transposing the data for the table;
   %macro trans(in = , out= , by= );
    proc sort data= &in;by &by; run;
	
	proc transpose data= &in out=&out;
		by &by;
		id cohort;
		var count;
	run;

   %mend;
   ** enrol;
   %trans(in=enrol, out=enrol2 ,by=%str(txt ord));
   %trans(in=itt, out=itt2 ,by=%str(txt ord));
   %trans(in=safe, out=safe2 ,by=%str(txt ord));
   %trans(in=imm, out=imm2 ,by=%str(txt ord));
   %trans(in=pk, out=pk2 ,by=%str(txt ord));
   %trans(in=line2, out=line2t ,by=%str(txt ord));
   %trans(in=line3, out=line3t ,by=%str(txt ord));
   %trans(in=FU, out=FU2,by=%str(txt ord));
   %trans(in=NFU, out=NFU2 ,by=%str(txt ord));
   %trans(in=NFUREAS, out=NFUREAS21 ,by=%str(txt ord));

   data lines;
   length txt $250;
    set enrol2(in=a) itt2(in=b) safe2(in=c) imm2(in=d) pk2(in=e) line2t(in=f);
	array sr[*] a b c d e f;
	 do i=1 to dim(sr);
	  if sr[i] eq 1 then srt=i;
	 end;	 
		%align(old=&armlis ,new= &nname , BigN=arm);
	run;

 	data fu2;
  		set fu2;
  	%align(old=&armlis ,new= &nname , BigN=arm);
	run;

	data nfu2; 
	set nfu2;
		%align(old=&armlis ,new= &nname , BigN=arm);
	run;

   %macro denom();
   array a[*] &armlis;
	array b[*] denom1 -denom&Narm; 
		do i=1 to dim(a);
			 if a[i] eq . then b[i]= 0;
			 else b[i]= a[i];
		end;
   run;
   %mend;

   %macro align2;   	 
 	array a[*] &armlis;
 	array b[*] denom1-denom&Narm; 
 	array c[&Narm] $50 &nname;
   	%do i=1 %to &Narm; 
    	if a[&i] eq . then a[&i]= 0;
		if b[&i] > 0 then c[&i]= put(a[&i],6.)||" ("||put((a[&i]/b[&i])*100,5.1)||"%)";
        if a[&i]> 0 and index(compress(c[&i]),'(0.0%)')> 0 then c[&i]= put(a[&i],6.)||" ("||"<0.1"||"%)";
        
		if a[&i] eq 0 then c[&i]= "0";
		if substr(compress(c[&i]),1,1) eq "0" then c[&i]= put(0,6.);
		c[&i]= tranwrd(c[&i],"100.0%)", "100%)");
		if c[&i] ne "" then c[&i]= "  "||c[&i];
	
	%end;
   %mend;
	
   data l3denom(keep= denom: ord);
    set line2t;
	 ord =7;
	 %denom;
	run;

  data line3t(keep= txt ord cohort: total denom: );
   length txt $250;
		merge line3t l3denom;				
 	select(strip(txt));
		when("Intercurrent illness that prevents further administration of treatment") txt= "Inter-current Illness[1]";
		when("General or specific changes in the subject's condition render further treatment unacceptable for the subject in the judgment of the investigator") 
								  txt="General or Specific Changes in the Subject's Condition[2]";
    	when("Lost to follow-up") txt= "Lost to Follow-up";
		when("Withdrawal of consent") txt= "Withdrawal by Subject";
		when("AE") txt= "Adverse Event (not including Death)";
		when("Protocol non-compliance") txt= "Protocol Non-compliance";
		otherwise txt=strip(txt);
	end;
  by ord;  
 run;

  data line3shell;
  length txt $250;
  ord=7;
	 do txt=  "Lost to Follow-up", "Withdrawal by Subject", "Death" , "Adverse Event (not including Death)", "Disease Progression" ,  "Inter-current Illness[1]",
				"General or Specific Changes in the Subject's Condition[2]" ,  "Protocol Non-compliance", "Other";
				output;
     end;
  run;

	proc sort data= line3t; by txt ord;run;
	proc sort data= line3shell; by txt ord; run;

	data line3t(keep= txt ord &nname); 
		merge line3t line3shell;
		%align2;
	by txt ord;
	run;

  data nfu3t(keep= denom: ord);
   set nfu2;
    ord= 11;
   %denom;   
   run;
  

   data pg2_shell;
	  length txt $250;
	  do txt=  "Lost to follow-up", "Withdrawal of consent", "Other", "Death";
	  output;
	  end;
  run;

 proc sort data= pg2_shell ;by txt; run;
 proc sort data= NFUREAS21; by txt; run;

  data NFUREAS21;
	 length txt $250;
    merge NFUREAS21 pg2_shell;
  	ord= 11;
   by txt;  
  run;

   data NFUREAS21(keep= txt ord &nname srt3); 
     merge NFUREAS21 nfu3t;
	 	%align2;
	  by ord;	  
	  if strip(txt) eq "Lost to follow-up" then srt3=1;
		else if strip(txt) =  "Withdrawal of consent" then srt3=2;
			else if strip(txt) = "Other" then srt3=4;
				else if strip(txt)=  "Death" then srt3=3;
	run;

	data shell;
	length  txt $250;
	 srt=0;
	 do txt= "Total Number of Enrolled Subjects", "Primary Reason for Discontinuation" ;
	 output;
	 end;
	 run;

	proc sort data=lines; by ord srt txt; run;

	data page1(keep= pg ord srt txt &nname); 
	 set shell lines line3t;
	 pg=1;
	 if ord <=5 then ord=1;
	 else ord=2;	 
	run;

  data page1; 
 	set page1;
   if txt eq "Total Number of Subjects Discontinued Treatment" then do;
   	ord=2;
	srt=0;
	srt1=0;
   end;
   if txt eq "Primary Reason for Discontinuation" then do;
     ord=2;
	 srt=0;
	 srt1=1;
   end;
   if srt eq . then srt=1;
 array l[9] $250 ("Lost to Follow-up", "Withdrawal by Subject", "Death" , "Adverse Event (not including Death)", "Disease Progression" ,  "Inter-current Illness[1]",
				"General or Specific Changes in the Subject's Condition[2]" ,  "Protocol Non-compliance", "Other");
	do i=1 to 9;
	 if txt eq l[i] then srt1=i;
	 end;
	 drop i;

  run;

   data line;
	 length txt $250;
	 txt= "Reason for not Completing Follow-up";
 run;

  	data page2;
	length txt $250;
	 set  fu2(in=a) nfu2(in=b) line(in=c) NFUREAS21(in=d);
	 pg=2;
	 ord=1;
	 if strip(txt) eq "Lost to follow-up" then txt= "Lost to Follow-up";
	 if a or b or c then srt=0; 
	 else srt=2;
	 if a then srt1=1;
	 if b then srt1=2;
	 if c then srt1=3;
	 if d then srt1=4;
	run; 	

	proc sort data=page2; by pg ord srt srt1 srt3; run;
	proc sort data=page1; by pg ord srt srt1; run;

	data final; 
	set page1 page2;
	%packtext(length=50,delim="/",flow="~n",vartx=txt_pack,indent1=2,indent2=2,dim=60, linout=us_txt,linect=counter1,
    		  varlist=txt,sp_lline ='N',out_type="rtf");
	if srt ne 0 then txt_pack= "  "||txt_pack;
	run;

*** to get the labels for column headers;
%getlabel();
 
ODS RTF FILE=".\Output\T140102.rtf" STYLE=StyleA;
ODS LISTING CLOSE;
ODS escapechar = "~"; 
%get_tf(TLF_PROGNAME=T140102,escapechar= ~);
options nobyline;
options nocenter;
proc report data =final nowd 
         headline headskip split="$"  spacing=0 formchar(2)='_' missing; 

  column  pg ord srt srt1 srt3 txt_pack &colhead1 txt_pack &colhead2 txt_pack &colhead3;

   define pg/order noprint;   
   define ord/order order=internal noprint;
   define srt/order order=internal noprint;
   define srt1/order order=internal noprint;
   define srt3/order order=internal noprint;
   
   define txt_pack  / " "  style = [just=l cellwidth=39% asis = on]; 
 %do i=1 %to 3;
   define cohort&i/ "&&Hlabel&i.$(N = &&arm&i)"  style(header) = [just=c cellwidth=20% asis = on]
								  style(column) = [just=l cellwidth=20% asis = on]; 
 %end;

%do i=4 %to 6;
   define cohort&i/ "&&Hlabel&i.$(N = &&arm&i)"  style(header) = [just=c cellwidth=20% asis = on]
								  style(column) = [just=l cellwidth=20% asis = on]; 
 %end;

%do t=7 %to &Narms;
 define cohort&t/ "&&Hlabel&t.$(N = &&arm&t)"  style(header) = [just=c cellwidth=20% asis = on]
								  style(column) = [just=l cellwidth=20% asis = on]; 
 %end;

 define tot/ "Total$(N = &&arm&Narm)"  style(header) = [just=c cellwidth=20% asis = on]
								  style(column) = [just=l cellwidth=20% asis = on]; 
   
   break after pg/page;

   compute before ord;
     line "";
   endcomp;   
run;

ods rtf close;
ods listing;

*** call rtf_post to post process footer text and body wrapping ***;
%rtf_post();
%end;
%mend;
%tab;
