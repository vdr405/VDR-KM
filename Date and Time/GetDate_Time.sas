
%MACRO GETDTM(INDATE=,  OUTDATEN=, OUTTIME=);
 **IF COMPLETE DATE;
 IF LENGTHN(&INDATE.)=10 THEN &OUTDATEN = INPUT(&INDATE., ??ANYDTDTE21.); 
 
 **IF COMPLETE DATE AND TIME;
 ELSE IF INDEX(&INDATE., 'T') THEN  DO;
   &OUTDATEN = INPUT(SCAN(&INDATE., 1,'T'), ??ANYDTDTE21.);
   &OUTTIME  = INPUT(SCAN(&INDATE., 2, 'T'), TIME5.); 
 END;
 FORMAT &OUTDATEN DATE9. &OUTTIME TIME5.; 
%MEND;


%MACRO GETDT(INDATE=,  OUTDATEN=);
 **IF COMPLETE DATE;
 IF LENGTHN(&INDATE.)=10 THEN &OUTDATEN = INPUT(&INDATE., ??ANYDTDTE21.); 
 FORMAT &OUTDATEN DATE9. ;
%MEND; 