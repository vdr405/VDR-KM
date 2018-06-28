/*****************************************************************************************
 * PROGRAM :     FIND_DUPS.sas
 * FUNCTION:     To Find Duplicates
 * DATASETS:     All SDTM Domains     
 *........................................................................................
 * AUTHOR:       Dinesh Vippala       DATE: 10/05/2017 
 * Validated By:                      DATE: 
 *              
 *........................................................................................
 * REVISION HISTORY:
 * Name   Date     Description 
*****************************************************************************************/
%macro find_dups;

/*** Get list of all SDTM Domains and Vars ***/
proc contents data=sdtm._all_ out=cont(keep=name memname ) noprint;
run;

/*** Remove Supplemental domains, --SEQ, --BLFL, --DY variables ***/
data cont; 
set cont;
length var1 var2 var3 $20;
 name=strip(upcase(name));
 memname=strip(upcase(memname));
 var1= compress(memname||"BLFL");
 var2= compress(memname||"SEQ"); 
 var3= compress(memname||"DY"); 
 if ((substr(memname,1,4) ne "SUPP" ) and lengthn(memname) eq 6 ) or (name eq var1) or (name eq var2) or (name eq var3) or(strip(name) in ("DOMAIN" "STUDYID"))  then delete;
run;

/*** Get list of Vars in each domain into macros ***/
proc sort data= cont; by memname; run;

data cont; 
set cont end=eof;
if first.memname then i+1;
by memname;
call symput('ds'||Strip(put(i,best.)), strip(memname));
if eof then call symput('max',strip(put(i,best.)));
run;


/*** Output XML report to output multiple tabs  ****/
 ods TAGSETS.EXCELXP path = "&path" file = "Duplicates in SDTM at record level.XML" style = Printer
      options (Orientation = 'landscape' embedded_titles = 'yes' 
               embedded_footnotes = 'yes' sheet_name= "Duplicates"  
               Autofit_height = 'yes' autofilter="ALL" absolute_column_width= "15"
               frozen_headers = '3' frozen_rowheaders = '3'             
               Width_Fudge = '0.70') ;

/**** Get sort order using all vars ***/
%do k=1 %to &max;
proc sql noprint;
 select distinct(name) into: vars&k separated by ' ' from cont where strip(memname) eq "&&ds&k";
quit;

%put Vars for SDTM.&&DS&K : &&vars&k;

%let key&k = %sysfunc(scan(&&Vars&k,-1, " "));

/*** Find absolute duplicates: meaning using all vars ****/
proc sort data=SDTM.&&DS&K out=&&DS&K tagsort; 
    by &&VARS&k;
run;

data &&DS&K;
 set &&DS&K;
     if ^(first.&&key&k and last.&&key&k);
     by &&vars&k;
 run;
    
/*** Check for number of obs ***/
%let dsid= %Sysfunc(open( &&DS&K));
%let Numobs= %sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%put &numobs;

%IF &NUMOBS >0 %THEN %DO;
   /*** Get the contents of dataset and use those attributes for xml output ****/
   proc contents data=&&DS&K out=contdata noprint;
   run;

   proc sort data=contdata;
          by varnum;
   run;  

   /*** Get column width ***/
data contdata ;
     set contdata;
     label_len = lengthn(label);
     min_length = min(10, label_len);     
      if max(length,min_length) > 20 then lengthx = 20 ;
     else lengthx = max (length,min_length);
run;

proc sql noprint;
     select lengthx into: abs_width separated by ', '
     from contdata;
quit;
%put &abs_width;  


title;footnote;
title bold italic  color=Tomato  bcolor=Yellow h=14pt f='Thorndale AMT' J=L "Duplicates in &&DS&K by record level"; 
footnote1 bold italic color=Tomato  bcolor=Yellow h=13pt f='Thorndale AMT' J=L "Note 1: Use these report for review purpose only. Do not use these outputs for any analysis purposes";
footnote2 bold italic color=Tomato  bcolor=Yellow h=13pt f='Thorndale AMT' J=L "Note 2: Duplicates were determined by using all variables in SDTM domain, excluding --SEQ variables";
 
ods TAGSETS.EXCELXP 
         options (absolute_column_width= "&abs_width"
                    sheet_name= "&&DS&K" ); 
      
      %let dsid2 = %sysfunc(open(contdata));
      %let dsobs = %sysfunc(attrn(&dsid2, NOBS));

      proc print data = &&DS&K noobs WIDTH=MIN label rows=page ;

      %do i__ = 1 %to &dsobs.;
          %let dsrc=%sysfunc(fetchobs(&dsid2, &i__.));
          %let varnum=%sysfunc(varnum(&dsid2, NAME));
          %let varname=%sysfunc(getvarc(&dsid2,&varnum.));
          %let typenum=%sysfunc(varnum(&dsid2, TYPE));
          %let vartype=%sysfunc(getvarn(&dsid2,&typenum.));
          %if &vartype. = 2 %then %do;   /** character variables **/
              var &varname. /style (data) = {tagattr = 'format:text' just = left} 
                             style (head) = { just = center};
          %end;
          %else %if &vartype. = 1 %then %do;   /** numeric variables **/
              var &varname. /style (data) = {tagattr = 'format:text' just = right}
                             style (head) = { just = center};
          %end;
      %end;
      run;  

      %let rc = %sysfunc(close(&dsid2));
  
%END;

%end;

 ods TAGSETS.EXCELXP close;
   title;footnote; 

/**** Clean work Folder **/
proc datasets memtype=data lib=work kill nolist;
run;
quit;


%mend;
