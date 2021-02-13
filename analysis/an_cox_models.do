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

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

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

* Stratified by region
stcox i.sgtf, strata(region)


* Plot scaled schoenfeld residuals
estat phtest, plot(1.sgtf)
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

* Interaction with time
stcox i.sgtf, tvc(i.sgtf) strata(stp)



*********************************************************************
/* Demographically adjusted HR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 household_size ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3, strata(region)

			 
			 
*********************************************************************
/* Demographically adjusted HR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week ib2.agegroupA, strata(region)


			 
***********************************************************
/* Fully adjusted HR - age as spline, continuous hh size */
***********************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3, strata(region)



**************************************************
/* Fully adjusted HR - age grouped, cat hh size */
**************************************************

* Stratified by region
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			 ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week, strata(region)
			 
			 
			 
*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3

* Stratified by STP
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, strata(stp)
			 
* Stratified by region
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, strata(region)

* Plot scaled schoenfeld residuals
estat phtest, plot(1.sgtf)
graph export ./output/minadj_cox_shoen.svg, as(svg) replace

* KM plot
sts graph,	surv by(sgtf) ///
			ylabel(0.8(0.05)1) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/minadj_cox_km.svg, as(svg) replace
		
* Smoothed hazard plot
sts graph,	haz by(sgtf) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/minadj_cox_haz.svg, as(svg) replace

* Interaction with time
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3, strata(region) tvc(i.sgtf)


* Stratified by UTLA
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, strata(utla_group)

			 
log close
