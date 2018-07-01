/*****************************************************************************************
 * Study:       INCB53914-101
 * PROGRAM:     G_T_DEMO.SA
 * FUNCTION:    To QC DEMOG DATASET
 *
 * DATASETS:  ADSL               
 *........................................................................................
 * AUTHOR:       Dinesh Vippala      DATE: 08/29/2017
 * Validated by:  Dinesh Vippala  Date:
 *........................................................................................
 * REVISION HISTORY: 
 * AUTHER:                        DATE:
 * Purpose: 
 * 
*****************************************************************************************/
%INIT;

PROC DATASETS LIB=WORK NOLIST KILL;  RUN;  QUIT;

dm "Clear log";
dm "Clear output";


%macro tot(ds);
data &ds;
 set &ds;
  output;
  trt01an=99;
  output;
run;
%mend;


%macro aept(where= ,Where2= , prog= , freq=  , line=  , grp= ); 

data adae(keep= usubjid trt: ae: ); 
set derived.adae;
    IF AEBODSYS = " " THEN AEBODSYS = "_UNCODED";
    IF AEDECOD = " "  THEN AEDECOD = "_UNCODED:" ||STRIP(AETERM);
    where &where &where2;
run;

data adsl;
 set derived.adsl;
  where &where;
run;

%tot(adae);
%tot(adsl);

proc sql noprint;
    create table aept as 
        select trt01an, count(distinct usubjid ) as cnt,1 as ord from adae group by trt01an;
    create table aept2 as 
        select trt01an, aedecod, count(distinct usubjid ) as cnt,2 as ord from adae group by trt01an,aedecod;     
    create table denom as 
        select trt01an,  count(distinct usubjid ) as denom from adsl group by trt01an;     
      select max(trt01an) into: trt separated by "," from adsl;
      select count(distinct trt01an) into: TRTCNT separated by "," from adsl;
quit;

data counts;
 set aept aept2;
  by trt01an;
run;

data counts;
 merge counts(in=a) denom(in=b);
  by trt01an;
  length perc $50;
  if n(cnt,denom) eq 2 and denom>0 then do;
      perc=compress(striP(put(cnt,best.))||"("||strip(put((cnt/denom)*100,5.1 ))||")");
      if cnt >0 and index(perc,"(0.0)")>0 then perc= compress(striP(put(cnt,best.))||"(<0.1)");      
  end;
  if cnt eq 0 then perc= "0(0.0)";
 run;

proc sort data= counts; by  ord aedecod; run;

proc transpose data =counts out=counts2 prefix=col;
 by ord aedecod;
 var perc;
 id trt01an;
run;

data counts2; 
set counts2;
 if col&trt. ne "" then cnt&trt. =input(scan(col&trt.,1,"("),best.);
 run;


%if &freq = Y %then %do;
 proc sort data=counts2; by ord  descending cnt&trt. ; run;
%end;
%else %do;
    proc sort data=counts2; by ord aedecod; run;    
%end;

data Valida(keep=  variable C1-C&trtcnt.);
 set counts2;
 length variable $200;
    if ord eq 1 and &line eq 1  then variable= 'Number (%) of Subjects with Any Adverse Events';
    else variable= strip(aedecod);
    srt=_n_;
    array a[*]  col:;
    array b[&trtcnt.] $40 C1 - C&trtcnt.;
    do i=1 to dim(b);
        if a[i] ne "" then b[i]=compress(a[i]);
    end;
    if variable ne "" then variable=compress(compress(variable,,'kn'));
 run;


DATA ORIG;
     SET MOCK.&prog;
     ARRAY C[*]  $20 C1-C&trtcnt ;
         DO I=1 TO DIM(C);
            C[I]=COMPRESS(C[I]);
        END;
        if variable ne "" then variable=compress(compress(variable,,'kn'));
    KEEP  Variable C1 - C&trtcnt ;
RUN; 

 
ODS RTF FILE="/sasdata/IncyteBioStat/Projects/Oncology/INCB24360_207/Validation/QC Forms/QC_&prog._%SYSFUNC(TODAY(),DATE9.).RTF";
PROC COMPARE DATA=ORIG COMPARE=VALIDA LISTALL;
 RUN;
/*** assign sysinfo value into a global macro var ***/ 
%global compinfo1 ; 
%let compinfo1  = &sysinfo;
%comp_report(dsname=&prog);
ODS RTF CLOSE;


%mend;
*** TRTGRP= E;
%*aept(where=%str(SAFFL eq "Y" and TRTGRP="E"),Where2= %str(and  TRTEMFL eq "Y"), prog= t_aept_e, freq= Y , 
            line=1, grp=E); 
%*aept(where=%str(SAFFL eq "Y" and TRTGRP="E"),Where2= %str(and  TRTEMFL eq "Y" and aeser eq "Y" ), prog= t_saept_e, freq= Y , 
            line=1, grp=E); 
*** TRTGRP= C;
%aept(where=%str(SAFFL eq "Y" and TRTGRP="C"),Where2= %str(and  TRTEMFL eq "Y"), prog= t_aept_c, freq= Y , 
            line=1, grp=C); 
%aept(where=%str(SAFFL eq "Y" and TRTGRP="C"),Where2= %str(and  TRTEMFL eq "Y" and aeser eq "Y" ), prog= t_saept_c, freq= Y , 
            line=1, grp=C); 
*** TRTGRP= D;
%aept(where=%str(SAFFL eq "Y" and TRTGRP="D"),Where2= %str(and  TRTEMFL eq "Y"), prog= t_aept_d, freq= Y , 
            line=1, grp=D); 
%aept(where=%str(SAFFL eq "Y" and TRTGRP="D"),Where2= %str(and  TRTEMFL eq "Y" and aeser eq "Y" ), prog= t_saept_d, freq= Y , 
            line=1, grp=D); 

            

 
