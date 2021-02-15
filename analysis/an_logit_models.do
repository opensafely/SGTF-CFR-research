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


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



*********************************************************************
/* Demographically adjusted OR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat i.home_bin ///
			i.region ib1.rural_urban5 ib1.start_week ib2.agegroupA ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



***********************************************************
/* Fully adjusted OR - age as spline, continuous hh size */
***********************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat household_size ///
			i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



**************************************************
/* Fully adjusted OR - age grouped, cat hh size */
**************************************************

glm risk_28 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform

est store fully

* Adjusted absolute odds
margins male#agegroupA if sgtf==0, post

* Save odds estimates
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
list inv_est1 sq_var in 1/8

* Re-Calculate CI
gen lb = inv_est1 - 1.96*sq_var
gen ub = inv_est1 + 1.96*sq_var

order lb ub, after(inv_est1)

* Convert to risk
gen risk0 = (inv_est1 / (1 + inv_est1))*100
gen r_lb0 = (lb / (1 + lb))*100
gen r_ub0 = (ub / (1 + ub))*100


est restore fully

* Adjusted absolute odds
margins male#agegroupA if sgtf==1, post

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
list inv_estx1 sq_varx in 1/8

* Re-Calculate CI
gen lb1 = inv_estx1 - 1.96*sq_varx
gen ub1 = inv_estx1 + 1.96*sq_varx

order lb1 ub1, after(inv_estx1)

* Convert to risk
gen risk1 = (inv_estx1 / (1 + inv_estx1))*100
gen r_lb1 = (lb1 / (1 + lb1))*100
gen r_ub1 = (ub1 / (1 + ub1))*100


gen risk_labels = "F: 0-<65" in 1
replace risk_labels = "F: 65-<75" in 2
replace risk_labels = "F: 75-<85" in 3
replace risk_labels = "F: 85+" in 4

replace risk_labels = "M: 0-<65" in 5
replace risk_labels = "M: 65-<75" in 6
replace risk_labels = "M: 75-<85" in 7
replace risk_labels = "M: 85+" in 8

noi disp "ABSOLUTE RISK ESTIMATES"
list risk_labels risk0 r_lb0 r_ub0 risk1 r_lb1 r_ub1 in 1/8


***********************************
/* Output table of absolute risk */
***********************************

cap file close tablecontent

file open tablecontent using ./output/table3_abs_risk.txt, write text replace

file write tablecontent ("Table 3: Absolute risk of death by 28-days") _n _n

file write tablecontent ("Sex/Age group")		_tab ///
						("non-VOC (95% CI)")	_tab ///
						("VOC (95% CI)")		_n

forvalues i=1/8 {
	
	preserve
		keep if _n == `i'
		file write tablecontent %9s (risk_labels) _tab %4.2f (risk0) (" (") %4.2f (r_lb0) ("-") %4.2f (r_ub0) (")") _tab %4.2f (risk1) (" (") %4.2f (r_lb1) ("-") %4.2f (r_ub1) (")") _n
	restore

}

file close tablecontent



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
margins sgtf


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

* Age group marginal odds
margins sgtf, over(agegroupA)


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

* Ethnicity marginal odds
margins sgtf, over(eth2)



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

* Comorbidity marginal odds
margins sgtf, over(comorb_cat)


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

* IMD marginal odds
margins sgtf, over(imd)



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

* Epi week marginal odds
margins sgtf, over(start_week)


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

* NHS region marginal odds
margins sgtf, over(region)



*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, ///
			family(bin) link(logit) eform

* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced


* Age grouped
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin, ///
			family(bin) link(logit) eform

* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced


* With region
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin i.region, ///
			family(bin) link(logit) eform


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



log close



insheet using ./output/table3_abs_risk.txt, clear
export excel using ./output/table3_abs_risk.xlsx, replace
