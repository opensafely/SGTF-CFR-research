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

* Stratified by UTLA
stcox i.sgtf, strata(utla_group)


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
stcox i.sgtf, tvc(i.sgtf) strata(utla_group)

* Interaction with time excluding November
stcox i.sgtf if study_start >= date("01dec2020", "DMY"), strata(utla_group)
stcox i.sgtf if study_start >= date("01dec2020", "DMY"), tvc(i.sgtf) strata(utla_group)


*********************************************************************
/* Demographically adjusted HR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 household_size ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3, strata(utla_group)

			 
			 
*********************************************************************
/* Demographically adjusted HR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week ib2.agegroupA, strata(utla_group)


			 
***********************************************************
/* Fully adjusted HR - age as spline, continuous hh size */
***********************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3, strata(utla_group)
			 
est store e_no_int

/* Subgroup analyses */

* Epi week
stcox i.sgtf##ib1.start_week i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat age1 age2 age3, strata(utla_group)

est store e_weekX

* Test for interaction
lrtest e_no_int e_weekX

* Epi week VOC vs. non-VOC HR
lincom 1.sgtf, eform						// week 1
lincom 1.sgtf + 1.sgtf#2.start_week, eform	// week 2
lincom 1.sgtf + 1.sgtf#3.start_week, eform	// week 3
lincom 1.sgtf + 1.sgtf#4.start_week, eform	// week 4
lincom 1.sgtf + 1.sgtf#5.start_week, eform	// week 5
lincom 1.sgtf + 1.sgtf#6.start_week, eform	// week 6
lincom 1.sgtf + 1.sgtf#7.start_week, eform	// week 7



* Comorbidities
stcox i.sgtf##ib0.comorb_cat i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3, strata(utla_group)

est store e_comorbX

* Test for interaction
lrtest e_no_int e_comorbX

* Comorbidities VOC vs. non-VOC HR
lincom 1.sgtf, eform						// no comorbs
lincom 1.sgtf + 1.sgtf#1.comorb_cat, eform	// 1 comorb
lincom 1.sgtf + 1.sgtf#2.comorb_cat, eform	// 2+ comorbs



* Ethnicity
stcox i.sgtf##ib1.eth2 i.male ib1.imd ib0.comorb_cat ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3, strata(utla_group)

est store e_eth2X

* Test for interaction
lrtest e_no_int e_eth2X

* Ethnicity VOC vs. non-VOC HR
lincom 1.sgtf, eform					// White
*lincom 1.sgtf + 1.sgtf#2.eth5, eform	// S Asian
*lincom 1.sgtf + 1.sgtf#3.eth5, eform	// Black
*lincom 1.sgtf + 1.sgtf#4.eth5, eform	// Mixed
lincom 1.sgtf + 1.sgtf#5.eth2, eform	// Other
lincom 1.sgtf + 1.sgtf#9.eth2, eform	// Missing



* Age group
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week, strata(utla_group)
			 
est store e_age

stcox i.sgtf##ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week, strata(utla_group)
			 
est store e_ageX

* Test for interaction
lrtest e_age e_ageX

* Age group VOC vs. non-VOC HR
lincom 1.sgtf, eform						// 0-<65
lincom 1.sgtf + 1.sgtf#2.agegroupA, eform	// 65-<75
lincom 1.sgtf + 1.sgtf#3.agegroupA, eform	// 75-<85
lincom 1.sgtf + 1.sgtf#4.agegroupA, eform	// 85+



**************************************************
/* Fully adjusted HR - age grouped, cat hh size */
**************************************************

* Stratified by region
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			 ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week, strata(utla_group)
			 
			 
			 
*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3

* Stratified by STP
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, strata(stp)
			 
* Stratified by region
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, strata(utla_group)

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
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3, strata(utla_group) tvc(i.sgtf)


			 
log close
