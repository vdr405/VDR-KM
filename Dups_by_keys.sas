/*****************************************************************************************
 * PROGRAM :     Dups_by_Keys.SAS
 * FUNCTION:     To Find Duplicates in SDTM Domains by key variables
 * DATASETS:          
 * USAGE: DS= SDTM Domain Name
 *           Keys= list of variables that are supposed to be unique for each record. Exclude Sequence
 *                  Number from this.     
 *........................................................................................
 * AUTHOR:       Dinesh Vippala       DATE: 10/05/2017 
 * Validated By:                      DATE: 
 *              
 *........................................................................................
 * REVISION HISTORY:
 * Name   Date     Description 
*****************************************************************************************/
%macro dups_by_Keys(ds=  , keys=  );

/*** Generic keys for Standard SDTM Domains *****/
/*** Make changes as per study design. Pay attention to time point variables ****/ 
data  __Keys;   
length domain $10 Keys $100;
     domain= "DM";
     Keys = "STUDYID USUBJID";
output;
     domain= "CO";
     Keys = "STUDYID USUBJID COSEQ";
output;
     domain= "SE";
     Keys = "STUDYID USUBJID ETCD SESTDTC";
output;
     domain= "SV";
     Keys = "STUDYID USUBJID VISITNUM";
output; 
    domain= "CM";
     Keys = "STUDYID USUBJID CMTRT CMSTDTC";
output;
     domain= "EX";
     Keys = "STUDYID USUBJID EXTRT EXSTDTC EXTPTNUM EXDOSE"; /**** Add EXTPT based on study;*/
output;
     domain= "SU";
     Keys = "STUDYID USUBJID SUTRT SUSTDTC";
output;
     domain= "AE";
     Keys = "STUDYID USUBJID AEDECOD AESTDTC";
output;
     domain= "DS";
     Keys = "STUDYID USUBJID DSDECOD DSTERM DSSTDTC";
output;
    domain= "MH";
    Keys = "STUDYID USUBJID MHDECOD MHSTDTC";
output;
    domain= "DV"; 
    Keys = "STUDYID USUBJID DVTERM DVSTDTC";
output;
    domain= "CE"; 
    Keys = "STUDYID USUBJID CETERM CESTDTC";
output;
    domain= "EG"; 
    Keys = "STUDYID USUBJID EGCAT EGTESTCD VISITNUM EGDTC";/** EGTPTREF EGTPTNUM" ;*/
output;
    domain= "IE";
    Keys = "STUDYID USUBJID IETESTCD";
output;
    domain= "LB";
     Keys = "STUDYID USUBJID LBCAT LBTESTCD LBSPEC LBDTC VISITNUM"; /* LBTPTREF LBTPTNUM*/
output;
    domain= "PE";
    Keys = "STUDYID USUBJID PETESTCD VISITNUM";
output;
    domain= "QS";
    Keys = "STUDYID USUBJID QSCAT QSTESTCD VISITNUM";/* QSTPTREF QSTPTNUM"; */
output;
    domain= "SC";
    Keys = "STUDYID USUBJID SCTESTCD";
output;
    domain= "VS"; 
    Keys = "STUDYID USUBJID  VSTESTCD  VISITNUM VSDTC";/* VSTPTREF VSTPTNUM"; */
output;
    domain= "DA";  
     Keys = "STUDYID USUBJID DATESTCD DADTC DAORRES";     
output;     
    domain= "MB";  
     Keys = "STUDYID USUBJID MBTESTCD VISITNUM MBTPTREF";/* MBTPTNUM";*/
output;
    domain= "MS";
    keys= "STUDYID USUBJID MSTESTCD VISITNUM MSTPTREF";/* MSTPTNUM";*/
output;
    domain= "PC";
    keys= "STUDYID USUBJID PCTESTCD VISITNUM  PCTPTNUM"; /*PCTPTREF*/
output;
    domain= "PP";
    keys= "STUDYID USUBJID PPTESTCD PPCAT VISITNUM PPTPTREF";
output;
    domain= "FA" ;
    keys= "STUDYID USUBJID FACAT FASCAT FATESTCD FAOBJ VISITNUM ";/*FATPTREF  FATPTNUM*/
output;
    domain= "TA";
    keys= "STUDYID ARMCD TAETORD";
output;
    domain= "TE";
    keys= "STUDYID ETCD";
output;
    domain= "TV"; 
    keys= "STUDYID VISITNUM ARMCD";
output;
     domain= "TI";
     keys= "STUDYID IETESTCD";
output;
    domain= "TS";
    keys= "STUDYID TSPARMCD TSSEQ";
output;
    domain= "RELREC";
    keys= "STUDYID RDOMAIN USUBJID IDVAR IDVARVAL RELID";
output;
run;

/*** Append custom domains keys info ***/
%let exist= %sysfunc(exist(keys));
%put &exist;

%if &exist >1 %then %do;
%put "Appending Custom Keys info......";

 data __keys;
  set __keys(in=a) Keys(in=b);
   if a then srt=1;
   else srt=2;
 run;

 proc sort data=__keys;
  by domain srt;
 run;

 data __keys (drop=srt);
  set __keys;
  if last.domain;
  by domain;
 run;

%end;

/*** Get list of all SDTM Domains and merge keys info ***/
proc contents data=sdtm._all_ out=cont(keep=memname ) noprint;
run;

data cont(drop=memname); 
set cont;
 domain=upcase(memname);
run;

proc sort data=cont nodupkey; 
    by domain;
run;

data __keys;
 set __keys;
    domain=strip(upcase(domain));
    keys= strip(upcase(keys));
run;

proc sort data=__Keys; by domain; run;

data cont;
  merge cont(in=a) __Keys(in=b);
   if (a and b) or (index(domain,"SUPP") and a);
    by domain;
    **** Keys info for SUPP-- Domains **;
    if index(domain,"SUPP") >0 then keys= "STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM";
run;

/*** Get list of Vars in each domain into macros ***/
proc sort data= cont; by domain keys; run;

data cont; 
set cont end=eof;
    if first.domain then i+1;
    by domain;
    call symput('ds'||Strip(put(i,best.)), strip(domain));
    if eof then call symput('max',strip(put(i,best.)));
run;

/*** Output XML report to output multiple tabs  ****/
 ods TAGSETS.EXCELXP path = "&path" file = "Duplicates in SDTM Domains by Key variables.XML" style = Printer
      options (Orientation = 'landscape' embedded_titles = 'yes' 
               embedded_footnotes = 'yes' sheet_name= "Duplicates"  
               Autofit_height = 'yes' autofilter="ALL" absolute_column_width= "15"
               frozen_headers = '3' frozen_rowheaders = '3'             
               Width_Fudge = '0.70') ;


/**** Get sort order using all vars ***/
%do k=1 %to &max;
proc sql noprint;
 select distinct(keys) into: vars&k separated by ' ' from cont where strip(domain) eq "&&ds&k";
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
title bold italic color=Tomato bcolor=Yellow h=14pt J=L "Duplicates in &&DS&K by key Variables &&vars&k"; 
footnote1 bold italic color=Tomato bcolor=Yellow h=13pt J=L "Note 1: Use these report for review purpose only. Do not use these outputs for any analysis purposes";
footnote2  bold italic color=Tomato bcolor=Yellow h=13pt J=L "Note 2: Duplicates were determined by using generic list of variables for standard domains. To make";
footnote3  bold italic color=Tomato bcolor=Yellow h=13pt J=L "        any changes contact your programmer";
 
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
