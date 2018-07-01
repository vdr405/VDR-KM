*************************************************************************
*             CLIENT:  OncoMed 
*           PROTOCOL:  59R5-001
*       PROGRAM NAME:  T14030102.sas
*        SAS VERSION:  SAS V9.1.3
*            PURPOSE:  
*
*        USAGE NOTES:  Batch Submit via PC SAS v9.1.3  
*        INPUT FILES:  adb.ADAE& adb.Header
*       OUTPUT FILES:  T03.rtf & corresponding log file 
*
*             AUTHOR:  DINESH VIPPALA
*       DATE CREATED:  08MAY2012
*        

*   MODIFICATION LOG:   
*************************************************************************
* DATE          INITIALS        MODIFICATION DESCRIPTION
*************************************************************************
* DDMONYYYY                    Complete description of modification made
*                               including reference to source of change.
*
*************************************************************************
*  © 2011 Pharmaceutical Product Development, Inc.
*  All Rights Reserved.
*************************************************************************;

** calling in macro prog;
%include "TM1401050X.sas";

** calling Table parameters;
%tab(in1= adcm,                              /** Table main dataset **/    
      master= %str(adb.header),                /** dset to get the BigN counts **/
      out= T14010501 ,                           /** final dset that goest to report **/
      where= (saffl eq "Y" and cmfl in ("C" "PC")), /** n counts subset **/
      whr=( saffl eq "Y"),                /** BigN subset condition **/     
      by1= aesoc,                /** SOC_NAME/ATC2 information **/
      miss1= %str(Uncoded[1]),      /** If by1 is missing then replace by1 with miss1 **/
      by2=aept ,               /** PT_NAME/PREFNAM information **/
      miss2=  aeterm,                  /** If by2 is missing then replace by2 with miss2 **/
      by3=AETERM,              /** CONVT/MEDVT/AEVT information **/
      popid= SAFFL,      /** Population variable **/
      srt=%str(ALPHA DESCENDING), /* sorting order preference - enter 'ALPHA' for sorting to be done by alphabetical order 'FREQ' for desceding frequency order*/
      line1=%STR(Total Number of Related Treatment Emergent Adverse Events), /** ENTER  text for first line of the table**/      
	  line2= %str(Number of Subjects With at Least One Related Treatment Emergent Adverse Event),
      lines=18,
       perc=Y);  /*** maximum number of lines per page */
 
