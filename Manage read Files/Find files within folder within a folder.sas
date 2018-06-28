/*** a macro to check for number of obs ***/
%macro onoff(in);
%global nobs;
%let dsid= %sysfunc(open(&in));
%let nobs= %sysfunc(attrn(&dsid, nobs));
%let rc= %sysfunc(close(&dsid));
%put &nobs;
%mend; 

/*** a macro to  find all files in a folder ***/
%macro findfile(path= , out= );
 data &out;
  length fnamex $200 fpath $500;
  rc=filename("datadir","&path");
  did=dopen("datadir");
  nfiles = dnum(did);

  call symput('nfiles',compress(put(nfiles,8.))) ;
  if nfiles >= 1 then do i = 1 to nfiles;
    fnamex = dread(did,i);
    fpath= "&path./"||strip(fnamex);
    output; 
  end;
  rc = dclose(did);
run;
%mend;

/*** initial call to find all files and subfolders - PASS1 ****/
%findfile(path=%str(/sasdata/IncyteBioStat/Projects/Oncology/INCB53914_101/Validation) , out= allfiles);


%macro findfolders(in=  );

/*** Label for Repeating macro loop ****/
%repeat: 

/*** seperate files and folder **/
data folder files; 
set &in;
    if scan(fnamex,2,".") eq ""  then output folder;
        if scan(fnamex,2,".") ne ""  then output files;
run;
 
%onoff(folder);
%if &nobs>0 %then %do;
 data _null_; 
  set folder end=eof;
   call symput('maxfldr',strip(put(_N_,best.)));
   call symput('folder'||strip(put(_N_,best.)),strip(fnamex));
   call symput('fpath'||strip(put(_N_,best.)),strip(fpath));
 run;    

   %do i=1 %to &maxfldr;
      %findfile(path= &&fpath&i, out=folder&i);                  
      proc append base= files data =folder&i force nowarn;     
      run;      

   %end;

%end;

/*** Check for additional **/
data folder;
set files;
    if scan(fnamex,2,".") eq ""  then output folder;        
run;
 
%onoff(folder); 

%if &nobs >0 %then %do;
data allfiles;
 set files;
run;
/**** If more folders exist, repeat this loop ****/
%goto repeat;

%end;

proc datasets memtype=data lib=work  nolist;
    save  files;
run;
quit;


%mend;
%findfolders(in=allfiles); /***&in=dataset name from PASS-1 ****/

