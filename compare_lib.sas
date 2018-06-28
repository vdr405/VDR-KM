

proc printto; run;
libname old "C:\Documents and Settings\dvippala_v\Desktop\old";
proc contents data= old._all_ out= old noprint;
run;

proc sort data=old nodupkey; by memname; run;

data old; 
set old;
call symput('ds'||strip(put(_n_,best.)),strip(memname));
call symput('max',strip(put(_N_,best.)));
by memname;
run;

%macro comp;
 %do i=1 %to &max;
	proc compare base=old.&&ds&i compare=sdtm.&&ds&i listall;
	run;
 %end;
%mend;
%comp;
proc printto; run;
