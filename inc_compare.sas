/*****************************************************************************************
 * Study:       
 * PROGRAM:     INC_COMPARE.SAS
 * FUNCTION:    To Generate compare reports from &SYSINFO
 *
 * DATASETS:     
 * USAGE : Call macro INC_COMPARE(base=  ,compare=  , compid= , by = ,id= , var= , options=);
 *           BASE= Production Programmer dataset
 *           COMPARE=QC Programmer dataset  
 *           COMPID= SAS dataset name in your proc compare Base/ a ID for your Compare
 *           BY = BY variables List for By group comparision
 *           ID = ID variables List
 *           VAR =VAR variables List- Be cautions when using VAR variables
 *           OPTIONS= Other options for proc compare. EX:Options= %str(CRIT=0.000000001)
 * Sample Call:  
 *                  
 * %inc_compare(base= %str(Derived.ADSL),compare=%str(MOCK.ADSL) ,compid=QC_G_ADSL,by = ,id= %str(SUBJID) , var= , options= %str(CRIT=1E-14));
 *
 *........................................................................................
 * AUTHOR:       Dinesh Vippala        DATE: 01/12/2018
 *........................................................................................
 * REVISION HISTORY: 
 *
 *
 * 
 *****************************************************************************************/

/**** Assign a libname to validation folder ****/
/**** Compare dataset will be output here ****/
%let path= &PROJECTPATH/Validation;
%put &path;
libname _val_ "&path";

/**** A macro to check for number of obs ****/
%macro onoff(dsin=);
    %global numobs;    
    %let dsid= %Sysfunc(open(&dsin));
    %let Numobs= %sysfunc(attrn(&dsid,nobs));
    %let rc=%sysfunc(close(&dsid));
    %put  "Number of obs in &dsin : &numobs";
%mend; 

%macro inc_compare(base=  ,compare=  , compid= , by = ,id= , var= , options=  );

/**** Proc compare ***/
ODS RTF FILE="&Projectpath/Validation/QC Forms/&compid._%SYSFUNC(TODAY(),DATE9.).RTF";

proc compare base= &base compare=&compare out=DIFF &options OUTBASE OUTCOMP OUTDIF OUTNOEQUAL LISTALL ;
 %if &by^= %then  BY &by;;
 %if &id^= %then  ID &id;;
 %if &var^= %then VAR &var;;
run;;

ODS RTF CLOSE;    

/*** assign sysinfo value into a global macro var to preserve it outside INC_COMPARE***/ 
%global compinfo1 ;
%let compinfo1  = &sysinfo;
%put "Macro compare reportes from SYNINFO: &SYSINFO is saved in COMPINFO1:&COMPINFO1";

/**** From DIFF dataset only keep vars that has mismatches ****/
data  DIFF2;
    set DIFF;
         if strip(upcase(_TYPE_)) eq "DIF" ;
run;

%onoff(dsin=DIFF2);

%if &numobs>0 %then %do;

/*** Get list of numeric and character variables from DIFF **/
proc contents data= DIFF2 out=_CONTx_ noprint;
run;

proc sql noprint;
 select distinct(name) into:_NUMVAR_ separated by " " from _CONTx_ where type eq 1;
 select distinct(name) into:_CHARVAR_ separated by " " from _CONTx_ where type eq 2;
quit;
 
/**** Only need names of variables that has mismatches..doing some post processing ***/
data DIFF3;   
 set DIFF2(drop= _TYPE_ _OBS_ ) end=eof;  
 retain _varlistx;
 length _varlistx $20000; 

 %if &_NUMVAR_  ^=    %then %do;      
    array ax_scl[*] &_NUMVAR_;
      do _iii_=1 to dim(ax_scl);            
           if ^missing(ax_scl[_iii_])  and indexw(_varlistx,vname(ax_scl[_iii_])) eq 0 then _varlistx=strip(_varlistx)||" "||strip(vname(ax_scl[_iii_])); 
      end;
      drop _iii_;

 %end;
 %if &_CHARVAR_  ^=   %then %do; 
      array bx_scl[*] &_CHARVAR_;
      do _iiix_=1 to dim(bx_scl);
          if index(upcase(bx_scl[_iiix_]),"X") eq 0  then call missing(bx_scl[_iiix_]);
          else if index(upcase(bx_scl[_iiix_]),"X") > 0  then bx_scl[_iiix_]= "x";
          if ^missing(bx_scl[_iiix_])  and indexw(_varlistx,vname(bx_scl[_iiix_])) eq 0 then _varlistx=strip(_varlistx)||" "||strip(vname(bx_scl[_iiix_])); 
      end;
       drop _iiix_;
 %end; 
 if eof;
run;
 
/**** Assign list of variables with mis matches to a macro variables ***/
proc sql noprint;
 select distinct(_varlistx) into:_KEEPVAR_   from DIFF3  ; 
quit;

data DIFFVAR (keep= _TYPE_ _OBS_  &_KEEPVAR_);
 set DIFF;
run;

proc datasets memtype=data lib=work nolist;
    delete DIFF2 DIFF3 _CONTx_;
run;
quit;

%end;


 data comp_data(keep= DSETNAME SYSINFO SYSDATE OUTCOME MESSAGE rename=(MESSAGE=DETAILS));
 length message $ 600  text $200 dsetname OUTCOME  $60  ;
 format sysdate datetime22.;
 array msg {17} $ 60 _temporary_ (
 " ",
"Dataset labels differ",
"Dataset types differ",
"Variable has different informat",
"Variable has different format",
"Variable has different length",
"Variable has different label",
"Base data set has observation not in Compare",
"Compare data set has observation not in Base",
"Base data set has BY group not in Compare",
"Compare data set has BY group not in Base",
"Base data set has variable not in Compare",
"Compare data set has variable not in Base",
"A value comparison was unequal",
"Conflicting variable types",
"BY variables do not match",
"Fatal error: comparison not done"
 );

 SYSINFO= &compinfo1; 
 SYSDATE= datetime(); *** Comparision date/time stamp;
 if SYSINFO =0 then Message="All Values are Equal"; *<---(&SYSINFO=0 WHEN NO DIFFERENCE DETECTED);
 else do;
     Message=" "; *<----------(VARIABLE 'Message' WILL STORE &SYSINFO MESSAGES);
    do k=1 to 16; *<----------(BECAUSE THERE ARE 16 POSSIBLE &SYSINFO MESSAGES);
        binval=2**(k-1); *<--(CONVERT 0,1,2,3...16 TO BINARY 1,2,4,8,16,32,64..);
        match=band(binval,SYSINFO); *<--(DO BITWISE TESTING WITH BAND FUNCTION);
        key=sign(match)*k; *<---(REVERT BINARIES TO REGULAR NUMBERS FOR ARRAY INDEXING);
        text=msg(key+1); *<---(GET Message MESSAGE TEXT FROM ARRAY VALUE);
        Message=catx(", ",Message,text); *<---(CONCATENATE IF MORE THAN ONE &SYSINFO MESSAGE);
    end;
 end;    
    dsetname= "&compid"; 
    if SYSINFO ^=  0 then Outcome="Did not Match:Check DIFF/DIFFVARS for more details";
    if SYSINFO =  0 then Outcome="Matched";
 run;

 /****  Retain the preferred order of display ****/
 data comp_data;
  retain DSETNAME SYSDATE SYSINFO OUTCOME DETAILS;
  set comp_data;
  run;

 /**** Check for existing comp_report ****/
%let exist=%sysfunc(exist(_val_.comp_report));
%put &exist;

%if &exist = 0 %then %do;
    data _val_.comp_report; **** Creae new dataset if there is none;
     set comp_data;
    run;
%end;
%else %do;
 data _val_.comp_report;
  set _val_.comp_report;
    if strip(upcase(dsetname)) eq strip(upcase("&compid")) then delete; **** Remove pervious SYSINFO lines for current compare;
 run;

 proc append base= _val_.comp_report data=comp_data FORCE;**** Append to existing dataset,if there is one;
 run; 

 proc sort data=_val_.comp_report;
  by dsetname;
 run;
%end;
 
*<---------------------------------------------------------------------------------------------------------------->;
*<------------------------------------- Output XLSX report to output multiple tabs -------------------------------->;
ods EXCEL file = "&path./&PROTOCOL._Proc_Compare_Summary_report.xlsx" style = Printer
      options (Orientation = 'landscape'   sheet_name= "SYSINFO"  
               /*Autofit_height = 'yes'*/ autofilter="ALL" absolute_column_width= "15"               
               /*Width_Fudge = '0.70'*/) ;

   
%macro gen_Specs(in=, Sheet= );
/*** Check for number of obs ***/
%onoff(dsin= &in); 

%IF &NUMOBS >0 %THEN %DO;

    data &in; 
        format _all_ ; 
        informat _all_;
    set &in;        
    run;
   /*** Get the contents of dataset and use those attributes for xml output ****/
   proc contents data= &in out=contdata noprint;
   run;

   proc sort data=contdata;
          by varnum;
   run;  

   /*** Get column width ***/
data contdata ;
     set contdata;
     label_len = lengthn(label);
     min_length = min(20, label_len);     
      if max(length,min_length) > 30 then lengthx = 30 ;
     else lengthx = max (20,length,min_length);          
run;

proc sql noprint;
     select lengthx into: abs_width separated by ', '
     from contdata;
quit;
%put &abs_width;  

ODS LISTING CLOSE;
title;footnote; 
ods EXCEL
         options (absolute_column_width= "&abs_width"
                    sheet_name= "&SHEET" ); 
      
      %let dsid2 = %sysfunc(open(contdata));
      %let dsobs = %sysfunc(attrn(&dsid2, NOBS));

      proc print data =  &IN noobs WIDTH=MIN label rows=page ;

      %do i__ = 1 %to &dsobs.;
          %let dsrc=%sysfunc(fetchobs(&dsid2, &i__.));
          %let varnum=%sysfunc(varnum(&dsid2, NAME));
          %let varname=%sysfunc(getvarc(&dsid2,&varnum.));
          %let typenum=%sysfunc(varnum(&dsid2, TYPE));
          %let vartype=%sysfunc(getvarn(&dsid2,&typenum.));
          %if &vartype. = 2 %then %do;   /** character variables **/
              var &varname. /style (data) = {tagattr = 'format:text' just = left width=100%} 
                             style (head) = { just = Center width=100%} ;
          %end;
          %else %if &vartype. = 1 %then %do;   /** numeric variables **/
              var &varname. /style (data) = {tagattr = 'format:General' just = right width=100%}
                             style (head) = { just = Center width=100%};
          %end;
      %end;
      run;  

      %let rc = %sysfunc(close(&dsid2));
  
%END;
 
%mend;
%gen_Specs(in=%str(_val_.comp_report), Sheet= %STR(SYSINFO));

 ods EXCEL close;
 title;footnote; 
 ODS LISTING;

 proc datasets memtype=data lib=work nolist;
    delete contdata   ;
 run; 

%mend inc_compare; 
 
