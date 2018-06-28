
libname xlsx xlsx "&ADaMSpec";
proc sql noprint;
 create table excel1 as
     select libname,memname
    from dictionary.tables
 where upcase(libname) = 'XLSX';
quit;
 