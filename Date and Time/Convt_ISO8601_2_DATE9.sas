
/*** Convert dates (including partial dates to Date9. format from YY-MM-DD(ISO8601) format ***/
/** Example **************
**** 2010-04-01->01APR2010 ***
***** 2012-04->APR2012 ****/
%macro convtdt(indt= , outdt=, type= , debug= N);
length &type.yr &type.mm &type.dd $5 &outdt $10 ;
    if lengthn(&indt) >=4 then &type.yr =scan(&indt,1,"-");
    if lengthn(&indt) >=6  then &type.mm =strip(scan(&indt,2,"-"));
    if lengthn(&indt) >= 8  then &type.dd =scan(&indt,3,"-");
    if &type.dd eq "" and &type.mm ne "" then &type.dd_= "01";
    else &type.dd_=  put(input(&type.dd,best.),z2.);
    if  &type.dd_ ne "" then XX&type=put(input(catx("-",&type.yr,&type.mm,&type.dd_),yymmdd10.),date9.);
    if &type.mm ne "" then &type.mm=substr(XX&type,3,3);
    if &indt ne "" then &outdt= cats(&type.dd,&type.mm,&type.yr);
    %if &debug =N %then %do;        
        drop &type.yr &type.mm &type.dd  xx&type  &type.dd_;
    %end;
%mend;
%convtdt(indt=CMSTDTC , outdt=ASTDTC, type= ss);
%convtdt(indt=CMENDTC , outdt=AENDTC, type= en);    
  