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


*Set up output file
cap file close tablecontent

file open tablecontent using ./output/table2_hr.txt, write text replace

file write tablecontent ("Table 2: Hazard ratios for VOC vs. non-VOC") _n

file write tablecontent ("Estimate")	_tab ///
						("HR (95% CI)")	_tab ///
						("P-value")		_n


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

* Output unadjusted
lincom 1.sgtf, eform
file write tablecontent ("Unadjusted") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Plot scaled schoenfeld residuals
estat phtest, plot(1.sgtf)
graph export ./output/unadj_cox_shoen.svg, as(svg) replace

* KM plot
sts graph,	surv by(sgtf) ///
			ylabel(0.995(0.001)1) ///
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
estat phtest, d

stcox i.sgtf if study_start >= date("01dec2020", "DMY"), tvc(i.sgtf) strata(utla_group)


*********************************************************************
/* Demographically adjusted HR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 household_size i.home_bin ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 ///
			 if eth2 != 6 ///
			 , strata(utla_group)

			 
			 
*********************************************************************
/* Demographically adjusted HR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat i.home_bin ///
			 ib1.rural_urban5 ib1.start_week ib2.agegroupA ///
			 if eth2 != 6 ///
			 , strata(utla_group)

lincom 1.sgtf, eform
file write tablecontent ("Demographically adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

			 
****************************************************
/* Fully adjusted HR - age as spline, cat hh size */
****************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_no_int

lincom 1.sgtf, eform
file write tablecontent ("Fully adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


/* Subgroup analyses */

file write tablecontent _n ("Subgroup analyses") _n 

* Epi week
stcox i.sgtf##ib1.start_week i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_weekX

* Test for interaction
lrtest e_no_int e_weekX

file write tablecontent ("Epi. week") _tab _tab %6.4f (r(p)) _n

* Epi week VOC vs. non-VOC HR
lincom 1.sgtf, eform						// week 1
file write tablecontent ("16Nov-22Nov") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#2.start_week, eform	// week 2
file write tablecontent ("23Nov-29Nov") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#3.start_week, eform	// week 3
file write tablecontent ("30Nov-06Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#4.start_week, eform	// week 4
file write tablecontent ("07Dec-13Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#5.start_week, eform	// week 5
file write tablecontent ("14Dec-20Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#6.start_week, eform	// week 6
file write tablecontent ("21Dec-27Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#7.start_week, eform	// week 7
file write tablecontent ("28Dec-04Jan") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



* Comorbidities
stcox i.sgtf##ib0.comorb_cat i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_comorbX

* Test for interaction
lrtest e_no_int e_comorbX

file write tablecontent ("Comorbidities") _tab _tab %6.4f (r(p)) _n

* Comorbidities VOC vs. non-VOC HR
lincom 1.sgtf, eform						// no comorbs
file write tablecontent ("None") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#1.comorb_cat, eform	// 1 comorb
file write tablecontent ("1") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#2.comorb_cat, eform	// 2+ comorbs
file write tablecontent ("2+") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



* Ethnicity
stcox i.sgtf##ib1.eth2 i.male ib1.imd ib0.comorb_cat ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_eth2X

* Test for interaction
lrtest e_no_int e_eth2X

file write tablecontent ("Ethnicity") _tab _tab %6.4f (r(p)) _n

* Ethnicity VOC vs. non-VOC HR
lincom 1.sgtf, eform					// White
file write tablecontent ("White") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

*lincom 1.sgtf + 1.sgtf#2.eth5, eform	// S Asian
*lincom 1.sgtf + 1.sgtf#3.eth5, eform	// Black
*lincom 1.sgtf + 1.sgtf#4.eth5, eform	// Mixed
lincom 1.sgtf + 1.sgtf#5.eth2, eform	// Other
file write tablecontent ("Not white") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

*lincom 1.sgtf + 1.sgtf#6.eth2, eform	// Missing



* Age group
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_age

stcox i.sgtf##ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_ageX

* Test for interaction
lrtest e_age e_ageX

file write tablecontent ("Age group") _tab _tab %6.4f (r(p)) _n

* Age group VOC vs. non-VOC HR
lincom 1.sgtf, eform						// 0-<65
file write tablecontent ("0-<65") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#2.agegroupA, eform	// 65-<75
file write tablecontent ("65-<75") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#3.agegroupA, eform	// 75-<85
file write tablecontent ("75-<85") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#4.agegroupA, eform	// 85+
file write tablecontent ("85+") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



* Include with 28-days follow-up
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & risk_pop==1 ///
			 , strata(utla_group)

file write tablecontent _n ("Sensitivity analyses") _n

lincom 1.sgtf, eform
file write tablecontent ("Min. 28-days follow-up") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Excluding week 1
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib2.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & start_week!=1 ///
			 , strata(utla_group)

lincom 1.sgtf, eform
file write tablecontent ("Excluding week 1") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



**************************************************
/* Fully adjusted HR - age grouped, cat hh size */
**************************************************

* Stratified by region
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			 ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
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

lincom 1.sgtf, eform
file write tablecontent ("Causal min. adjustment") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Plot scaled schoenfeld residuals
estat phtest, d
estat phtest, plot(1.sgtf)
graph export ./output/minadj_cox_shoen.svg, as(svg) replace

* KM plot
sts graph,	surv by(sgtf) ///
			ylabel(0.995(0.001)1) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/minadj_cox_km.svg, as(svg) replace
		
* Smoothed hazard plot
sts graph,	haz by(sgtf) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/minadj_cox_haz.svg, as(svg) replace

* Interaction with time
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3 ///
			 if eth2 != 6 ///
			 , strata(utla_group) tvc(i.sgtf)


* Close output table
file write tablecontent _n _n
file close tablecontent
			 

			 
log close


clear

insheet using ./output/table2_hr.txt, clear
export excel using ./output/table2_hr.xlsx, replace

