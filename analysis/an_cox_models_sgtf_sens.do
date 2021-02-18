********************************************************************************
*
*	Do-file:		an_cox_models_sgtf_sens.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	an_cox_models_sgtf_sens.log containing:
*					1-Unadjusted Cox models for SGTF
*					2-Adjusted Cox models for SGTF
*
********************************************************************************
*
*	Purpose:		This do-file runs Cox PH models, calculating HR for VOC 
*					vs. non-VOC
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_cox_models_sgtf_sens, replace t

clear

/*
use "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\output\cr_analysis_dataset.dta"
*/

use ./output/cr_analysis_dataset.dta

noi di "SUBSETTING ON COX CENSORED POPULATION"
keep if cox_pop==1

tab sgtf cox_death, row


*******************
/* Unadjusted HR */
*******************

stset stime_death, origin(study_start) fail(cox_death) scale(1) id(patient_id)

stcox i.sgtf

* Stratified by UTLA
stcox i.sgtf, strata(utla_group)


		 
****************************************************
/* Fully adjusted HR - age as spline, cat hh size */
****************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
estat phtest, d
			 			 
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & has_sgtf==1 ///
			 , strata(utla_group)	 
			 
*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin

* Stratified by STP
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, strata(stp)
			 
* Stratified by region
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, strata(utla_group)

			 
log close


clear


