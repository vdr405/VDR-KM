/*****************************************************************************************
 * PROGRAM :     DTHDTvsDB.SAS
 * FUNCTION:     To Find Dates that are reported after DTHDT
 * DATASETS:     All SDTM Domains     
 * USAGE: 
 *         
 *........................................................................................
 * AUTHOR:       Dinesh Vippala       DATE: 10/05/2017 
 * Validated By:                        DATE: 
 *              
 *........................................................................................
 * REVISION HISTORY:
 * Name   Date     Description 
*****************************************************************************************/
proc datasets memtype=data lib=work kill nolist;
run;
quit;

%macro STDTvsENDT(DSSET= );
 /*** Get list of datasets to be processed ***/
%let dsn= %sysfunc(countc(&dsset,":"));
%put Number of datasets to be processed: &dsn ; 

%do _k =1 %to  &dsn;

    %let ds&_k= %qcmpres(%qscan(%qscan(&dsset,&_k,"!"),1,":")); 
     /*** list of vars to be processed ****/ 
    %let stdt&_k= %qcmpres(%qscan(%qscan(%qscan(&dsset,&_k,"!"),2,":"),1,"/")); 
    %let endt&_k= %qcmpres(%qscan(%qscan(%qscan(&dsset,&_k,"!"),2,":"),2,"/")); 
    %put &&ds&_k &&stdt&_k &&endt&_k; 

    data &&ds&_k; 
    set SDTM.&&ds&_k;    
    attrib  comment length=$25 label= "Comments";
    /*** If variables doesn't exist skip to next ***/
    array a[*] _char_;
    do x=1 to dim(a);
        if upcase(strip(vname(a[x]))) eq upcase(strip("&&STDT&_K")) then fn1=1;
        if upcase(strip(vname(a[x]))) eq upcase(strip("&&ENDT&_K")) then fn2=1;
    end;
    if sum(fn1,fn2) ne 2 then do;   
        if fn1 eq . then put "WAR" "NING:&&STDT&_K doesn't exist. &&ds&_k will not be processed." ; 
        if fn2 eq . then put "WAR" "NING:&&ENDT&_K doesn't exist. &&ds&_k will not be processed.";
        goto next;    
    end;


    /**** To handle partial dates ****/
      if &&stdt&_k ne "" and lengthn(&&stdt&_k)>=4 then do;
       if lengthn(scan(&&stdt&_k,1,"T")) eq 10 then _stdtn= input(scan(&&stdt&_k,1,"T"),yymmdd10.); 
                    _stdty= input(scan(&&stdt&_k,1,"-"),best.); 
                    _stdtm= input(scan(&&stdt&_k,2,"-"),best.); 
                    _stdtd= input(scan(scan(&&stdt&_k,3,"-"),1,"T"),best.); 
      end;
      if &&endt&_k ne "" and lengthn(&&endt&_k)>=4 then do;
         if lengthn(scan(&&endt&_k,1,"T")) eq 10 then _endtn= input(scan(&&endt&_k,1,"T"),yymmdd10.); 
                    _endty= input(scan(&&endt&_k,1,"-"),best.); 
                    _endtm= input(scan(&&endt&_k,2,"-"),best.); 
                    _endtd= input(scan(scan(&&endt&_k,3,"-"),1,"T"),best.); 
      end;
      /**** If time point exist ****/
     if scan(&&stdt&_k,2,"T") ne "" then _stdts= input(scan(&&stdt&_k,2,"T"),time5.); 
     if scan(&&endt&_k,2,"T") ne "" then _endts= input(scan(&&endt&_k,2,"T"),time5.); 
    /**** FL Flag added for debug purposes ******/
      if n(_stdtn , _endtn) eq 2 and _stdtn > _endtn then fl=1;
      else if n(_stdtn , _endtn) eq 2 and n(_stdts , _endts) eq 2  and _stdtn = _endtn and _stdts > _endts then fl=1.5;
      else if  _stdty > _endty> . then fl=2;
      else if _stdty = _endty> . and _stdtm > _endtm> . then fl=3;
      else if _stdty = _endty> . and _stdtm = _endtm> . and _stdtd > _endtd> . then fl=1.25;      
      Comment= "&&stdt&_k"||" > "||"&&endt&_k";
      if fl >0 ;

      drop fl _: x fn1 fn2; 

     **** Skip to here;
      next: 

   run; 
%end;

/*** Find datasets with nobas ****/
proc contents data=work._all_ out=Cont(keep=memname NOBS where=(NOBS>0))  noprint;
run;


/*** Check for number of obs ***/
%let dsid= %Sysfunc(open(CONT));
%let Numobs= %sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%put &numobs;

%if &Numobs = 0 %then %do ;
 %put "No issues found to report. Exiting macro now..";
 %goto exit;
%end;


/*** Find list of  domain to report ****/

data cont2; 
set cont end=eof;
    if first.memname then i+1;
    by memname notsorted;
    call symput('ds'||Strip(put(i,best.)), strip(upcase(memname)));
    if eof then call symput('max',strip(put(i,best.)));
run;


/*** Output XML report to output multiple tabs  ****/
 ods TAGSETS.EXCELXP path = "&path" file = "Reported Start Dates are after End Date.XML" style = Printer
      options (Orientation = 'landscape' embedded_titles = 'yes' 
               embedded_footnotes = 'yes' sheet_name= "Duplicates"  
               Autofit_height = 'yes' autofilter="ALL" absolute_column_width= "15"
               frozen_headers = '3' frozen_rowheaders = '3'             
               Width_Fudge = '0.70') ;

%do i=1 %to &max;
   
   /*** Get the contents of dataset and use those attributes for xml output ****/
   proc contents data=&&DS&I out=contdata noprint;
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
title bold italic color=Tomato bcolor=Yellow h=14pt J=L "Collection or Reported Dates in &&DS&I are after Death Date"; 
footnote1 bold italic color=Tomato bcolor=Yellow h=13pt J=L "Note 1: Use these report for review purpose only. Do not use these outputs for any analysis purposes";

ods TAGSETS.EXCELXP 
         options (absolute_column_width= "&abs_width"
                    sheet_name= "&&DS&I" ); 
      
      %let dsid2 = %sysfunc(open(contdata));
      %let dsobs = %sysfunc(attrn(&dsid2, NOBS));

      proc print data = &&DS&I noobs WIDTH=MIN label rows=page ;

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
                       
/**** Remove old datasets **/
proc datasets memtype=data lib=work nolist;
delete &&ds&i; 
run;
quit;

%end;

 ods TAGSETS.EXCELXP close;
   title;footnote; 

%exit:
%mend;
