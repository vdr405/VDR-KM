*************************************************************************
*             CLIENT: 
*           PROTOCOL:
*       PROGRAM NAME:  T140101.sas
*        SAS VERSION:  SAS V9.1.3
*            PURPOSE:  
*
*        USAGE NOTES:  Batch Submit via PC SAS v9.1.3  
*        INPUT FILES:  adb.Header
*       OUTPUT FILES:  T140101.rtf & corresponding log file 
*
*             AUTHOR:  DINESH VIPPALA
*       DATE CREATED:  11MAR2013
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

proc sort data= adb.header out=header(where=(ITTFL eq "Y") keep= site cohort subject ittfl); by cohort SITE subject; run;

** to impute total column;
%dummy_trt(in=header);
** to get the list of cohorts in the study;
%getarms;


%macro tab;

 ** BiGn Counts;
 %getbign(in= adb.header, countvar=subject, trtvar=cohort ,where=(strip(ITTFL) eq "Y"));

 
 * check for Zero obs;
 %onoff(source= header);

 %if &numobs =0 %then %do;
 	 data report; 
   		txt= "There are no observations to report for this Table";
  	 run;

	 ODS RTF FILE=".\Output\T140101.rtf" STYLE=StyleA;
	ODS LISTING CLOSE;
	ODS escapechar = "~"; 
	%get_tf(TLF_PROGNAME=T140101,escapechar= ~);
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
	create table enrol as select cohort,site, count(distinct subject) as count from header group by cohort , site;	
	create table total as select cohort,2 as ord, count(distinct subject) as count from header group by cohort ;	
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
   %trans(in=enrol, out=enrol2 ,by=%str(site));
   ** Total;
   %trans(in=Total, out=Total2 ,by=%str(ord));
   
   data lines;
   length txt $250;
    set enrol2(in=a) total2(in=b);
	length txt $20;
	if a then do;
		srt=1;
		txt= strip(site);
	end;
	if b then do;
		srt=2;
		txt= "Total";
	end;
	pg=1;
		%align(old=&armlis ,new= &nname , BigN=arm);
	run;
 	
	proc sort data= lines; by srt txt; run;
	
*** to get the labels for column headers;
%getlabel();
 
ODS RTF FILE=".\Output\T140101.rtf" STYLE=StyleA;
ODS LISTING CLOSE;
ODS escapechar = "~"; 
%get_tf(TLF_PROGNAME=T140101,escapechar= ~);
options nobyline;
options nocenter;
proc report data =lines nowd 
         headline headskip split="$"  spacing=0 formchar(2)='_' missing; 

  column  pg  srt txt &colhead1
  			txt &colhead2 
  				txt &colhead3;

   define pg/order noprint;      
   define srt/order order=internal noprint;
   
   define txt  / "Site Name"  style = [just=l cellwidth=39% asis = on]; 
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

   compute before srt;
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
