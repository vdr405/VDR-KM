/*****************************************************************************************
 * PROGRAM :     IMP_DATES.SAS
 * FUNCTION:     To Impute partial dates
 * DATASETS:          
 * USAGE: DTC= SDTM CHAR Date
 *           DT= SDTM Num Date
 *          TYPE= For typical Start Dates use 1: Replace missing months with "JAN" and missing dates with "01".
 *                                           11: Repalce missing start dates with Treatment Start Dates
 *                For typical END Dates use 2: Replace missing months with "DEC" and missing dates with "31" or 
 *                                            last date of that month.
 *                                             21:Replace end dates with Treatment End Dates 
 *
 *........................................................................................
 * AUTHOR:       Dinesh Vippala       DATE: 10/05/2017 
 * Validated By:                      DATE: 
 *              
 *........................................................................................
 * REVISION HISTORY:
 * Name   Date     Description 
*****************************************************************************************/

PROC PRINTTO; RUN;

%macro Imp_dates(dtc= , dt= ,type=  );

/**** TYPE=1:Typical for Start Dates ****/
%if &type =1 %then %do;
 if &dtc ne " " and 4<= lengthn(&dtc)<10 then do;
 length _DD&type _MM&type _YY&type $4;
    _MM&type = scan(&dtc,2,"-");
    _YY&type=  scan(&dtc,1,"-");
    if _MM&type eq "" then _MM&type="01";
    _DD&type='01';        
    &dtc= catx("-", _YY&type, _MM&type, _DD&type);
 end;
  if &dtc ne "" then &dt= input(&dtc,yymmdd10.);
  drop _DD&type _MM&type _YY&type;
%end;

/**** TYPE=2: Typical for End Dates ****/
%if &type =2 %then %do;
    if &dtc ne " " and 4<= lengthn(&dtc)<10 then do;
         length  _MM&type _YY&type $4 ;
        _MM&type = scan(&dtc,2,"-");
        _YY&type=  scan(&dtc,1,"-");
        if _MM&type eq "" then _MM&type="12";        
        &dtc= catx("-", _YY&type, _MM&type);
        _&dtc=input(&dtc,anydtdte7.);
        &dtc= put(intnx('month',_&dtc,0,'E'),yymmdd10.);
     end;
  if &dtc ne "" then &dt= input(&dtc,yymmdd10.);
  drop _MM&type _YY&type _&dtc;
%end;

*********************************************************************************;
*****	To be continued for Type=11 and 21 ****************************************;
*********************************************************************************;
%mend;
