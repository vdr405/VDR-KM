
%let path =%str(/sasdata/IncyteBioStat/Projects/Oncology/INCB53914_101/Validation);

 data allfiles;
  length fnamex $200;
  rc=filename("datadir","&path");
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