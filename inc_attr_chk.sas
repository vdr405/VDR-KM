/*****************************************************************************************
 * Study:       
 * PROGRAM:     INC_ATTR_CHK.SAS
 * FUNCTION:    Check for Metadata issues for ADaM domains 
 *
 * DATASETS:     Derived._ALL_
 * USAGE :      -Run this macro in Project area. Once ran, Check "Metadata_report.sas7bdat" in 
 *                        "&Proejctpath/Validation" Folder 
 *              - All Findings must be addressed
 * Macro Call: %inc_attr_chk(excl=);
 *             Sample Call #1: When this check needs to be run on all Datasets under Derived
 *                             Folder use %inc_attr_chk;
 *             Sample Call #2: When you want to exclude some domains from this check, list those 
 *                              domains using &EXCL.
 *                            %inc_attr_chk(excl= %str('TEST' 'DSET2' 'FORMATS' ) );
 *........................................................................................
 * AUTHOR:       Dinesh Vippala        DATE: 03/32/2018
 * VALIDATOR: Don Zeng
 *........................................................................................
 * REVISION HISTORY: 
 *
 *
 * 
 *****************************************************************************************/
%init; 

/*** Assign Path for storing Metadata Validation Report ****/
%let path= %str(&PROJECTPATH/Validation);
%put &path;

libname _val_ "&path";
%macro onoff(dsin=);
    %global numobs;    
    %let dsid= %Sysfunc(open(&dsin));
    %let Numobs= %sysfunc(attrn(&dsid,nobs));
    %let rc=%sysfunc(close(&dsid));
    %put  "Number of obs in &dsin : &numobs";
%mend; 


%macro inc_attr_chk(excl= %str( ) );

%let excl= %upcase(&excl);

/*** Get Proc Contents of Derived Domains ****/
Proc contents data=Derived._all_ out= _x1(keep=name memname label memlabel where=(strip(upcase(memname)) ^in ( &excl ))) noprint;
run;

/**** Check for same label on more than one ADaM Domain *****/
proc sort data= _x1;
 by memlabel memname label name;
run;

data _meml(keep=memlabel _0); 
set _x1;
    length _0 $100;
    if ^first.memlabel and first.memname;
       _0= "Repeating Dataset label";
    by memlabel memname label name;
run;

data _x1;
 merge _x1(in=a) _meml(in=b);
  by memlabel;
  if a;
run;

proc sort data=  _x1;
    by memname memlabel label name;
run;

data _x2;
    set  _x1 ;
    by memname memlabel label name;
    length _1 - _16  _1a _1b _13a _14a $200 comments $2000 DD VV $8 DDD VVV $1;
    label  Dset_Len= "Dataset Name Length"
        Var_Len= "Variable Name Length"
        DsetLabel_Len= "Dataset Label Length"
        VarLabel_Len= "Variable Label Length";
    Dset_Len=Lengthn(memname);
    var_Len=Lengthn(name);
    DsetLabel_len=length(memlabel);
    varLabel_len=length(label);
    **** Dataset/ Variable lengths must be <=8;
    if lengthn(strip(memname))> 8 and lengthn(strip(name))> 8 then _1="Dataset and Variable Name Longer than 8 Chars";
    else if lengthn(strip(memname))> 8 and lengthn(strip(name))<= 8 then _1="Dataset Name Longer than 8 Chars";
    else if lengthn(strip(memname))<= 8 and lengthn(strip(name))> 8 then _1="Variable Name Longer than 8 Chars";
    
    **** Illegal Variable/dataset names;        
    DD= compress(memname,' ','ad');
    VV= compress(name,' ','ad');
    DDD=substr(strip(memname), 1,1);
    VVV=substr(strip(name), 1,1);
        
    if  DD ne "" and VV ne "" then _1a="Illegal Dataset and Variable Name. Contains:"||Strip(DD)||"/"||strip(VV);
    else if  DD ne "" and VV eq "" then _1a="Illegal Dataset Name. Contains:"||Strip(DD);
    else if  DD eq "" and VV ne "" then _1a="Illegal Variable Name. Contains:"||Strip(VV);
    
    if  anydigit(DDD)>0  and anydigit(VVV) >0 then _1b="Illegal Dataset and Variable Name. Name Starts with:"||Strip(DDD)||"/"||strip(VVV);
    else if  anydigit(DDD)>0  and anydigit(VVV) = 0 then _1b="Illegal Dataset Name. Name Starts with:"||Strip(DDD);
    else if  anydigit(DDD)=0  and anydigit(VVV) >0 then _1b="Illegal Variable Name. Name Starts with:"||Strip(VVV);      
        
    **** Dataset/Variablelabel lengths must be <=40;
    if lengthn(strip(memlabel))> 40 or lengthn(strip(label))> 40 then _2="Dataset or Variable Label Longer than 40 Chars";
    
    **** No Speical character allowed in Variable/Dataset names except "_";    
    if anypunct(compress(memname,"_"))>0  or anypunct(compress(name,"_"))>0 then  
        _3= "Illegal Dataset or Variable name:Contains non Alpha-Numerics";
        
    **** > or < symbols are not allowed;
    if indexc(memlabel,'<>') or indexc(label,'<>') then
        _4= "Illegal dataset or Variable Label: Contains '<>'";
        
    **** Unbalanced Single quotes ;
    if index(memlabel, "'") and mod(count(memlabel, "'"),2) ne 0 then
        _5= "Illegal dataset Label: Contains unbalanced single quote";
        
    **** Unbalanced Single quotes ;
    if index(label, "'") and mod(count(label, "'"),2) ne 0 then
        _6= "Illegal variable Label: Contains unbalanced single quote";
        
    **** Unbalanced Double quotes ;
    if index(memlabel, '"') and mod(count(memlabel, '"'),2) ne 0 then
        _7= "Illegal Dataset Label: Contains unbalanced Double quote";
        
    **** Unbalanced Double quotes;
    if index(label, '"') and mod(count(label, '"'),2) ne 0 then
        _8= "Illegal variable Label: Contains unbalanced Double quote";
        
    **** Unbalanced Apostorphe;
    if index(memlabel, '`')>0 /*and mod(count(memlabel, '`'),2) ne 0*/ then
        _9= "Illegal Dataset Label: Contains apostrophe";
        
        **** Unbalanced Apostorphe;
    if index(label, '`') >0 /*and mod(count(label, '`'),2) ne 0*/ then
        _10= "Illegal variable Label: Contains apostrophe";
        
   **** Unbalanced Brackets;
   if (count(label, "(") ne count(label,")") ) or
        (count(label, "[") ne count(label,"]") ) or
        (count(label, "{")>0 ne count(label,"}") ) then
        _11= "Illegal Variable Label: Contains unbalanced parethesis, brackets";
        
    **** Unbalanced Brackets;
    if (count(memlabel, "(") ne count(memlabel,")") ) or
        (count(memlabel, "[") ne count(memlabel,"]") ) or
        (count(memlabel, "{")>0 ne count(memlabel,"}") ) then
        _12= "Illegal Dataset Label: Contains unbalanced parethesis, brackets";
    **** Extra Spaces;
    if label ne strip(label) or label ne compbl(label) then
        _13= "Trailing, Leading or extra spaces in Variable Label";
    if name ne strip(name) then _13a= "Trailing or Leading in Variable Name";
    
    **** Extra Spaces;
    if memlabel ne strip(memlabel) or memlabel ne compbl(memlabel) then
        _14= "Trailing, Leading or extra spaces in dataset Label";    
        
    **** Missing Labels;
    if label eq "" or Memlabel eq "" then _15= "Dataset or Variable Label Missing";
    
    **** repeatingLabels;
    if ^(First.label and last.label) then  _16= "Repeating variable Label";

    Comments= catx("/",_0,_1,_1a,_1b,_2,_3, _4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_13a,_14, _15,_16);

    if comments ne "";
run;

data Metadata_report (keep=Memname Dset_len Memlabel DsetLabel_len Name Var_Len Label VarLabel_leN comments);
    retain Memname Dset_len Memlabel DsetLabel_len Name Var_Len Label VarLabel_leN comments;
    set _x2;
run; 

proc sort data=Metadata_report out= _val_.Metadata_report;
  by MEMNAME NAME;
run;


*<---------------------------------------------------------------------------------------------------------------->;
*<------------------------------------- Output XLSX report to output multiple tabs -------------------------------->;
ods EXCEL file = "&path./&PROTOCOL._ADaM_Metadata_Issues_report.xlsx" style = Printer
      options (Orientation = 'landscape'   sheet_name= "ADaM"  
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
%gen_Specs(in=Metadata_report, Sheet= %STR(ADaM));

 ods EXCEL close;
 title;footnote; 

%mend; 
%*inc_attr_chk;
%inc_attr_chk(excl= %str('ADVS_OLD' 'FORMATS' 'LB_CDTEST' 'TEST' ) );
 
*** Clear _VAL_ libname;
LIBNAME _VAL_ CLEAR;


