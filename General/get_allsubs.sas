proc contents data= sdtm._all_ out=test noprint;

run;



proc sort data= test nodupkey;
by memname;
run;

data _null_;
 set test end=eof;
 call symput('dset'||strip(put(_N_,best.)),strip(memname));
 call symput('max',strip(put(_N_,best.)));
run;

%macro all();

 data  all(keep= usubjid domain rdomain);
  set %do i=1 %to &max;  SDTM.&&Dset&i %end;;
  run;

  proc sort data= all nodupkey; by domain rdomain usubjid; run;
%mend;
%all;
