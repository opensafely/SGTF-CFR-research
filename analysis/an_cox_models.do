********************************************************************************
*
*	Do-file:		an_cox_models.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	an_cox_models.log containing:
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
log using ./logs/an_cox_models, replace t

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

* Stratified by STP
stcox i.sgtf, strata(stp)

* Test for non-PH
stphtest, log detail

* Plot scaled schoenfeld residuals
stphtest, plot(1.sgtf) yline(0)
graph export ./output/unadj_cox_shoen.svg, as(svg) replace

* KM plot
sts graph,	surv by(sgtf) ///
			ylabel(0.8(0.05)1) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/unadj_cox_km.svg, as(svg) replace
		
* Smoothed hazard plot
sts graph,	haz by(sgtf) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/unadj_cox_haz.svg, as(svg) replace



*********************************************************************
/* Demographically adjusted HR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by STP
stcox i.sgtf i.male ib1.imd ib1.eth5 household_size ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3, strata(stp)

			 
			 
*********************************************************************
/* Demographically adjusted HR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by STP
stcox i.sgtf i.male ib1.imd ib1.eth5 ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week i.agegroup, strata(stp)


			 
***********************************************************
/* Fully adjusted HR - age as spline, continuous hh size */
***********************************************************

* Stratified by STP
stcox i.sgtf i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3, strata(stp)



**************************************************
/* Fully adjusted HR - age grouped, cat hh size */
**************************************************

* Stratified by STP
stcox i.sgtf i.agegroup i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			 ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week, strata(stp)
			 
			 
			 
*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3

* Stratified by STP
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3, strata(stp)
			 

			 
log close
