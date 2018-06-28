/*****************************************************************************************
 * Study:      
 * PROGRAM:    Create_Prodrun 
 * FUNCTION:   To Create Prodrun program using all .SAS programs from study programs Folder
 *              Assumption#1: All programs start with "g_" ,"f_","l_", "t_" or "a_" and
 *                            ends with ".sas"
 *              Assumption#2: _makeformats.sas is the program name for titles&footnote
 * Output:      _prodrun_&sysdate..sas
 *........................................................................................
 * AUTHOR:        Dinesh Vippala       DATE: 09/1/2017
 *
 *........................................................................................
 * REVISION HISTORY: 
 * AUTHER:                        DATE:
 * Purpose: 
 * 
*****************************************************************************************/
DM "Clear log";
DM "Clear output";

%init;

proc datasets memtype=data lib=work kill;
run;
quit;

**********************    ASSIGN PATH HERE or USE DEFAULT &PROGRAMS **************************************;
%*let programs =%str(/sasdata/IncyteBioStat/Projects/Oncology/INCB53914_101/Programs);

**********************    ASSIGN RUN PARAMETERS HERE **************************************;
%let Version= 1;
%let stage= %str(dvip);
%let update=1;

********************* GET LIST OF ALL FILES IN &PATH ***************************;
 data allfiles;
  length fnamex $200;
  rc=filename("datadir","&PROGRAMS");
  did=dopen("datadir");
  nfiles = dnum(did);

  call symput('nfiles',compress(put(nfiles,8.))) ;
  if nfiles >= 1 then do i = 1 to nfiles;
    fnamex = dread(did,i);
    output;
    /*
    Put if conditions here to specify a subset of files, then move the "output;" into this if/then condition.
    */
  end;
  rc = dclose(did);
run;

********************* GET LIST OF .SAS FILES and ARRANGE THEN IN PROPER ORDER ***************************;
data sasfiles(keep=fnamex pr flag) xtra(keep = fnamex pr flag);
    set allfiles;
    if index(lowcase(strip(fnamex)), "g_adsl")>0 then pr=1; /***ADSL RUNS FIRST ***/
    else if scan(lowcase(strip(fnamex)),1, "_") eq "g" then pr=2; /****ALL OTHER DERIVED DATASETS RUN AFTER ADSL *****/ 
    else pr=3; /****** LAST PRIORITY FOR TLF's *******/

        if scan(lowcase(fnamex),1,"_") ^in("g" "t" "l" "f" "a") then flag=1;  /**** MARK ALL EXCLUDED FILES ****/
        else if   index(lowcase(fnamex),".bak")>0 and index(lowcase(fnamex),".sas")>0 then flag=1;
        if index(lowcase(strip(fnamex)), '.sas')>0 and flag ne 1 then output sasfiles;
        else if index(lowcase(strip(fnamex)), '.sas')>0 and flag eq 1 then output xtra;
run;


proc sort data=sasfiles; by pr fnamex; run;


data header;
length fnamex $200;
 fnamex= "/*********************************************************************************************";
 output;
 fnamex= "* Study:      "||strip("&STUDY");
 output;  
 fnamex="* PROGRAM:     _batchrun.SAS";
 output;
 fnamex="* FUNCTION:    To Create Listing of batchrun";
 output;
 fnamex="*";
 output;
 fnamex="*" ; 
 output;
 fnamex="*........................................................................................";
 output;
 fnamex="* AUTHOR:"||strip("&SYSUSERID")||"         DATE:"||strip("&sysdate");
 output;
 fnamex="*" ;
 output;
 fnamex="*........................................................................................";
 output;
 fnamex="* REVISION HISTORY:" ;
 output;
 fnamex="* AUTHER:                        DATE:";
 output;
 fnamex="* Purpose: ";
 output;
 fnamex="*" ;
 output;
 fnamex="*********************************************************************************************/";
 output;
 fnamex='%init;';
 output;
 fnamex='options nosymbolgen nomprint nomlogic;';
 output; 
 fnamex='%prodrun(programs=_makeformats.sas';
 output;
run;

Data prop;
 length fnamex $200;
 fnamex=',version='||"&version."||'1,';
 output;
 fnamex="stage="||"&stage."||",";
 output;
 fnamex="update ="||"&update."||");";
 output;
run;

data final(keep=fnamex);
set header sasfiles prop;
if fnamex ne "" then fnamex=strip(fnamex);
run;


/*
%let ps= %sysfunc(getoption(PS));
%let ls= %sysfunc(getoption(lS));

proc printto print="&PROGRAMS./_prodrun_&sysdate..sas" new ;
run;
options nobyline;
options ls=200 ps=400;
    proc report data= final nowindows;
    column fnamex;
    define fnamex/ " " ;
    run;
proc printto;
run;

options ps=&ps. ls=&ls.;

*/

/**** CREATE SAS PROGRAM FOR PRODRUN *******/

data _null_ ;          /* No SAS data set is created */ 
    set final; 
    FILE  "&PROGRAMS./_prodrun_&sysdate..sas" DLM=',' ;   
    PUT  fnamex;; 
run ;