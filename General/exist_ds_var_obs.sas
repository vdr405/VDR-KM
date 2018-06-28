/*****************************************************************************************
 * Study:       
 * PROGRAM:     Varexist.sas
 * FUNCTION:    To Find existance of a variable, dataset and count numbobs 
 * 
 *........................................................................................
 * AUTHOR:     Dinesh Vippala        DATE:  
 *........................................................................................
 * REVISION HISTORY: 
 * AUTHER:                               DATE: 
 * Purpose: 
 * 
*****************************************************************************************/

%macro exist(ds,var);
/*------------------------------------------------------------------------------------
Check for the existence of a specified dataset and variable and count number of obs 
-------------------------------------------------------------------------------------*/
%local dsid rc ;
%global dsexist varexist numobs;

/*------------- Check for dataset existance -------------------*/   
%let dsexist= %sysfunc(exist(&ds));

/*------------- Count Number of Obs if dataset exist -------------------*/   
%if &dsexist>0 %then %do;
    %put  " Dataset: &DS Present";
    %let dsid = %sysfunc(open(&ds));
    %let numobs=%sysfunc(attrn(&dsid,nobs));
        %if  &var ^= %then %do;
/*------------- Check for Variable existance -------------------*/   
            %let varexist= %sysfunc(varnum(&dsid,&var));  
            %if &Varexist >0 %then %put "Variable: &Var Present";
                                    %else %put "Variable: &Var NOT Present";        
        %end;
    %let rc=%sysfunc(close(&dsid));
%end;
%else %do;
    %put  " Dataset: &DS NOT Present";
%end;
/*------------ Print Summary Report in Log --------------*/
%put "Dataset &ds Existance" '(&dsexist > 0):' &dsexist; 
%if &dsexist>0 %then %do;
    %put "Number of Obs in &ds" '(&numobs):' &numobs;
    %if &varexist >0 %then %do;
        %put "Variable(&var) Present in &ds" '(&varexist):' &varexist;
    %end;
    %else %if &var ^=  %then %do;
        %put "Variable(&var) Not Present in &ds" '(&varexist):' &varexist;
    %end;
%end;
%mend exist;
%exist(DMDS2);
