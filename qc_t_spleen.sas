/*****************************************************************************************
 * Study:      
 * PROGRAM:    
 * FUNCTION:    TO QC Summary Table
 *
 * DATASETS:  ADSL                
 *........................................................................................
 * AUTHOR:       Dinesh Vippala      DATE: 09/28/2017
 * Validated by:  Dinesh Vippala    Date:
 *........................................................................................
 * REVISION HISTORY: 
 * AUTHER:                        DATE:
 * Purpose: 
 * 
*****************************************************************************************/
%INIT;

proc datasets memtype=data lib=work kill nolist;
run;
quit;
/*options mprint mlogic symbolgen;*/

%macro spleen(popid= ITTFL , partn=,prod= , trtc= trt01p );
proc sort data= derived.adim out=adim(where=((anl01fl eq "Y" or ablfl eq "Y" ) and &popid eq "Y" and partn eq &partn ));
 by &trtc paramcd param avisitn avisit usubjid;
run;

data adim; 
set adim;
 output;
 &trtc= "Total";
 output;
run;


proc sort data=adim;
   by &trtc paramcd param avisitn avisit;
run;

%macro stat(var= ,  out=  ,whr= ,rnd=1);

%if &rnd ^= %then %do;
    %let _rnd= %eval(&rnd+1);
    %let rnd1= %sysevalf(10**(-&rnd));
    %let rnd2= %sysevalf(10**(-&_rnd));
    %put &rnd1 &rnd2;
%end;

data val;
    set adim;
    if avisit ne "" then avisit=propcase(avisit);
    where &whr;
    if &trtc ne "" then &trtc=  compress(&trtc, "+ ");    
    x=lengthn(&trtc);
    if x>6 then st= x-5;
    else st=1;
    if  &trtc  ne "" then  &trtc = substr(&trtc,st);
run;

proc univariate data=val  noprint;    
 by &trtc paramcd param avisitn avisit;
 var &var;
 output out=&out n=n mean=mean median=med std=sd min=min max=max q1=q1 q3=q3;
run;

data &out; 
set &out;
 length row1 row2 row3 row4 row5 $100;
 array a[*] mean q1 q3 min max med;
 array b[*] $50 meanc q1c q3c minc maxc medc;
   do i=1 to dim(a);
    if a[i] ne . then b[i]= strip(put(round(a[i],&rnd1.),8.&rnd));
   end;
   drop i;
    if n ne . then row1= strip(put(n,best.));
    else if n eq . then row1= "0";
    if sd ne . then sdc=strip(put(round(sd,&rnd2.),9.&_rnd));
    *if n>0 and sd eq . then sdc= "NA";    
    if meanc ne "" and sdc ne "" then row2= strip(meanc)||"("||strip(sdc)||")";
    else if meanc ne "" and sdc eq "" then row2= strip(meanc)||"( )";
    if n(min,max)  eq 2 then row5="("||strip(Minc)||", "||striP(maxc)||")";
    if n(q1,q3)  eq 2 then row4="("||strip(q1c)||", "||striP(q3c)||")";
    if med ne . then row3= strip(medc);
run;

proc sort data= &out; 
    by paramcd param avisitn avisit;
run;

Proc Transpose data=&out out=T_&out prefix= COL;
    by paramcd param avisitn avisit;
    var row1 row2 row3 row4 row5;
    id &trtc;
run;

%mend;
%stat(var= base, out=base , whr = %str(ABLFL eq "Y"));
%stat(var= aval, out=aval, whr = %str(ANL01FL eq "Y" and PSTBLFL eq "Y"));
%stat(var= chg, out=chg, whr = %str(ANL01FL eq "Y" and PSTBLFL eq "Y"));
%stat(var= pchg, out=pchg, whr = %str(ANL01FL eq "Y" and PSTBLFL eq "Y"));

data final  ;
 set t_base(in=a) t_aval(in=b) t_chg(in=c) t_pchg(in=d);
 length variable $100;
  if a then srt=1;
  if b then srt=2;
  if c then srt=3;
  if d then srt=4;
  select(upcase(strip(_name_)));
   when("ROW1") VARIABLE= "n";
   when("ROW2") VARIABLE= "MEAN (STD)";
   when("ROW3") VARIABLE= "Median";
   when("ROW4") VARIABLE= "(Q1,Q3)";
   when("ROW5") VARIABLE= "(MIN,MAX)";
   otherwise VARIABLE= " ";
 end;
run;

proc sort data =final;
    by paramcd param avisitn avisit srt _name_;
run;

data avisit(keep= variable avisit: srt paramcd param );
 set final;
    variable= strip(avisit);
    if first.avisit;
    by paramcd param avisitn avisit;
run;

data avisit2;
 set avisit(where=(avisitn>0));   
   Variable= "Change from baseline";
   srt=3;
   output;
   srt=4;
   variable= "Percent change from baseline";
   output; 
run;

data final2; 
set final avisit avisit2;
if variable ne "" then variable=strip(variable);
run;

proc sort data=final2(rename=( COL10mgQD=c1  COL20mgQD=c2 COLtotal=c3) );
    by paramcd param avisitn avisit srt _name_;
run;

DATA PROD;
     SET MOCK.&prod;
     ARRAY C[*]  $20 C1-C3;
         DO I=1 TO DIM(C);
        C[I]=COMPRESS(C[I]);
     END;  
     if variable ne "" then variable=strip(variable);
     keep c1 - c3 variable;
RUN;

DATA COMP;
     SET FINAL2;
      ARRAY C[*]  $20 C1-C3;
         DO I=1 TO DIM(C);
        C[I]=COMPRESS(C[I]);
     END;  
          keep c1 - c3 variable;
          if variable eq "End Of Treatment" then variable= "END of Treatment" ;
          if variable eq "Follow Up" then variable= "Follow up";
RUN;
 
ODS RTF FILE="&projectpath/Validation/QC Forms/QC_&PROD._%SYSFUNC(DATE(),DATE9.).RTF";

PROC COMPARE DATA=PROD COMPARE=COMP LISTALL; RUN;
/*** assign sysinfo value into a global macro var ***/ 
%global compinfo1 ; 
%let compinfo1  = &sysinfo;
%comp_report(dsname=&PROD);

ODS RTF CLOSE;


%mend;
%spleen(popid= ITTFL,partn=2,prod=T_SPLEEN1);
%spleen(popid= SAFFL,partn=1,trtc=trt01a,prod=T_SPLEEN3);


 
