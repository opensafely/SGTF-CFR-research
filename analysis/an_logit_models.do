********************************************************************************
*
*	Do-file:		an_logit_models.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	an_logit_models.log containing:
*					1-Unadjusted OR and absolute risks for SGTF
*					2-Adjusted OR and absolute risks for SGTF
*					3-Subgroup analyses of OR and absolute risk
*
********************************************************************************
*
*	Purpose:		This do-file runs logit models, calculating relative (glm) and
*					absolute odds (margins)
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_logit_models, replace t

clear

/*
use "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\output\cr_analysis_dataset.dta"
*/

use ./output/cr_analysis_dataset.dta

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

noi di "SUBSETTING ON 28-DAY RISK POPULATION"
keep if risk_pop==1

tab sgtf risk_28, row



*******************
/* Unadjusted OR */
*******************

glm risk_28 i.sgtf, family(bin) link(logit) eform

* Absolute odds
margins sgtf



*********************************************************************
/* Demographically adjusted OR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 household_size i.home_bin ///
			i.region ib1.rural_urban5 ib1.start_week age1 age2 age3 ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform



*********************************************************************
/* Demographically adjusted OR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat i.home_bin ///
			i.region ib1.rural_urban5 ib1.start_week ib2.agegroupA ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform



***********************************************************
/* Fully adjusted OR - age as spline, continuous hh size */
***********************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform



**************************************************
/* Fully adjusted OR - age grouped, cat hh size */
**************************************************

glm risk_28 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform

est store fully

* Adjusted absolute risks
margins comorb_cat#male#agegroupA if sgtf==0, post asobserved

* Save risk estimates
matrix est = e(b)
matrix inv_est = est'
svmat inv_est

* Save SE estimates
matrix var = e(V)
matrix diag_var = vecdiag(var)
matrix inv_var = diag_var'
svmat inv_var
gen sq_var = sqrt(inv_var1)

noi disp "CHECK MARGINS ARE CORRECTLY CALCULATED TO MATCH ABOVE"
list inv_est1 sq_var in 1/24

* Re-Calculate CI
gen risk0 = inv_est1*100
gen lb0 = (inv_est1 - invnormal(0.975)*sq_var)*100
gen ub0 = (inv_est1 + invnormal(0.975)*sq_var)*100

order lb ub, after(risk0)


est restore fully

* Adjusted absolute odds
margins comorb_cat#male#agegroupA if sgtf==1, post asobserved

* Save odds estimates
matrix est1 = e(b)
matrix inv_estx = est1'
svmat inv_estx

* Save SE estimates
matrix var1 = e(V)
matrix diag_var1 = vecdiag(var1)
matrix inv_varx = diag_var1'
svmat inv_varx
gen sq_varx = sqrt(inv_varx1)

noi disp "CHECK MARGINS ARE CORRECTLY CALCULATED TO MATCH ABOVE"
list inv_estx1 sq_varx in 1/24

* Re-Calculate CI
gen risk1 = inv_estx1*100
gen lb1 = (inv_estx1 - invnormal(0.975)*sq_varx)*100
gen ub1 = (inv_estx1 + invnormal(0.975)*sq_varx)*100

order lb1 ub1, after(risk1)


gen risk_labels = "Female: 0-<65" in 1
replace risk_labels = "65-<75" in 2
replace risk_labels = "75-<85" in 3
replace risk_labels = "85+" in 4

replace risk_labels = "Male: 0-<65" in 5
replace risk_labels = "65-<75" in 6
replace risk_labels = "75-<85" in 7
replace risk_labels = "85+" in 8

replace risk_labels = "Female: 0-<65" in 9
replace risk_labels = "65-<75" in 10
replace risk_labels = "75-<85" in 11
replace risk_labels = "85+" in 12

replace risk_labels = "Male: 0-<65" in 13
replace risk_labels = "65-<75" in 14
replace risk_labels = "75-<85" in 15
replace risk_labels = "85+" in 16

replace risk_labels = "Female: 0-<65" in 17
replace risk_labels = "65-<75" in 18
replace risk_labels = "75-<85" in 19
replace risk_labels = "85+" in 20

replace risk_labels = "Male: 0-<65" in 21
replace risk_labels = "65-<75" in 22
replace risk_labels = "75-<85" in 23
replace risk_labels = "85+" in 24


***********************************
/* Output table of absolute risk */
***********************************

cap file close tablecontent

file open tablecontent using ./output/table3_abs_risk.txt, write text replace

file write tablecontent ("Table 3: Absolute risk of death by 28-days") _n _n

file write tablecontent ("Comorbidities/Sex/Age group")		_tab ///
						("non-VOC (95% CI)")				_tab ///
						("VOC (95% CI)")					_n

forvalues i=1/24 {
	
	preserve
		keep if _n == `i'
		if inlist(`i',5,13,21) {
			file write tablecontent _n
		}
		if `i'==1 {
			file write tablecontent _n ("No Comorbidities") _n
		}
		if `i'==9 {
			file write tablecontent _n ("1 Comorbidity") _n
		}
		if `i'==17 {
			file write tablecontent _n ("2+ Comorbidities") _n
		}
		file write tablecontent %9s (risk_labels) _tab %4.2f (risk0) (" (") %4.2f (lb0) ("-") %4.2f (ub0) (")") _tab %4.2f (risk1) (" (") %4.2f (lb1) ("-") %4.2f (ub1) (")") _n
	restore

}

file close tablecontent


* Risks as balanced
est restore fully
margins sgtf comorb_cat#male#agegroupA if sgtf==0, post asbalanced

est restore fully
margins sgtf comorb_cat#male#agegroupA if sgtf==1, post asbalanced

est restore fully
margins sgtf comorb_cat#male#agegroupA, post over(sgtf)

est restore fully
margins sgtf comorb_cat#male#agegroupA, post asbalanced over(sgtf)


***********************
/* Subgroup analyses */
***********************

/* Fully adjusted OR - age grouped, cat hh size */

glm risk_28 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_no_int

* Constant VOC effect over subgroups
lincom 1.sgtf, eform



/* Age group */
glm risk_28 i.sgtf##ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_ageX

lrtest e_no_int e_ageX

* Age group VOC vs. non-VOC OR
lincom 1.sgtf, eform						// 0-<65
lincom 1.sgtf + 1.sgtf#2.agegroupA, eform	// 65-<75
lincom 1.sgtf + 1.sgtf#3.agegroupA, eform	// 75-<85
lincom 1.sgtf + 1.sgtf#4.agegroupA, eform	// 85+



/* Ethnicity */
glm risk_28 i.sgtf##ib1.eth2 ib0.comorb_cat ib2.agegroupA i.male ib1.imd ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_ethX

* Test for interaction
lrtest e_no_int e_ethX

* Ethnicity VOC vs. non-VOC OR
lincom 1.sgtf, eform					// White
*lincom 1.sgtf + 1.sgtf#2.eth5, eform	// S Asian
*lincom 1.sgtf + 1.sgtf#3.eth5, eform	// Black
*lincom 1.sgtf + 1.sgtf#4.eth5, eform	// Mixed
lincom 1.sgtf + 1.sgtf#5.eth2, eform	// Other
*lincom 1.sgtf + 1.sgtf#6.eth2, eform	// Missing



/* Comorbidities */
glm risk_28 i.sgtf##ib0.comorb_cat ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_comorbX

* Test for interaction
lrtest e_no_int e_comorbX

* Comorbidities VOC vs. non-VOC OR
lincom 1.sgtf, eform						// no comorbs
lincom 1.sgtf + 1.sgtf#1.comorb_cat, eform	// 1 comorb
lincom 1.sgtf + 1.sgtf#2.comorb_cat, eform	// 2+ comorbs



/* IMD */
glm risk_28 i.sgtf##ib1.imd ib2.agegroupA i.male ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_imdX

* Test for interaction
lrtest e_no_int e_imdX

* IMD VOC vs. non-VOC OR
lincom 1.sgtf, eform				// 1 least deprived
lincom 1.sgtf + 1.sgtf#2.imd, eform	// 2
lincom 1.sgtf + 1.sgtf#3.imd, eform	// 3
lincom 1.sgtf + 1.sgtf#4.imd, eform	// 4
lincom 1.sgtf + 1.sgtf#5.imd, eform	// 5 most deprived



/* Epi week */
glm risk_28 i.sgtf##ib1.start_week ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_weekX

* Test for interaction
lrtest e_no_int e_weekX

* Epi week VOC vs. non-VOC OR
lincom 1.sgtf, eform						// week 1
lincom 1.sgtf + 1.sgtf#2.start_week, eform	// week 2
lincom 1.sgtf + 1.sgtf#3.start_week, eform	// week 3
lincom 1.sgtf + 1.sgtf#4.start_week, eform	// week 4
lincom 1.sgtf + 1.sgtf#5.start_week, eform	// week 5
lincom 1.sgtf + 1.sgtf#6.start_week, eform	// week 6
lincom 1.sgtf + 1.sgtf#7.start_week, eform	// week 7



/* NHS region */

/*
glm risk_28 i.sgtf i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.region, ///
			family(bin) link(log) eform
			
est store e_region
*/

glm risk_28 i.sgtf##i.region ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_regionX

* Test for interaction
lrtest e_no_int e_regionX

* NHS region VOC vs. non-VOC OR
lincom 1.sgtf, eform					// East
lincom 1.sgtf + 1.sgtf#1.region, eform	// East mids
lincom 1.sgtf + 1.sgtf#2.region, eform	// London
lincom 1.sgtf + 1.sgtf#3.region, eform	// North E
lincom 1.sgtf + 1.sgtf#4.region, eform	// North W
lincom 1.sgtf + 1.sgtf#5.region, eform	// South E
lincom 1.sgtf + 1.sgtf#6.region, eform	// South W
lincom 1.sgtf + 1.sgtf#7.region, eform	// West mids
lincom 1.sgtf + 1.sgtf#8.region, eform	// Yorks & Hum



*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, ///
			family(bin) link(logit) eform



* Age grouped
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin, ///
			family(bin) link(logit) eform



* With region
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin i.region, ///
			family(bin) link(logit) eform




log close



insheet using ./output/table3_abs_risk.txt, clear
export excel using ./output/table3_abs_risk.xlsx, replace
