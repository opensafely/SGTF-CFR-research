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
*	Purpose:		This do-file runs risk models, calculating relative (glm) and
*					absolute risk (margins)
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

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 household_size care_home_type ///
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

glm risk_28 i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat care_home_type ///
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
			i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 care_home_type ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



**************************************************
/* Fully adjusted OR - age grouped, cat hh size */
**************************************************

glm risk_28 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week care_home_type ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform


* Adjusted absolute odds
margins agegroupA#male comorb_cat, over(sgtf) post

* Save odds estimates
matrix est = e(b)
matrix inv_est = est'
svmat inv_est

* Save SE estimates
matrix var = e(V)
matrix diag_var = vecdiag(var)
matrix inv_var = diag_var'
svmat inv_var
gen sq_var = sqrt(inv_var)

noi disp "CHECK MARGINS ARE CORRECTLY CALCULATED TO MATCH ABOVE"
list inv_est sq_var in 1/22

* Re-Calculate CI
gen lb = inv_est1 - 1.96*sq_var
gen ub = inv_est1 + 1.96*sq_var

order lb ub, after(inv_est1)

* Convert to risk
gen risk = inv_est1 / (1 + inv_est1)
gen r_lb = lb / (1 + lb)
gen r_ub = ub / (1 + ub)

gen risk_labels = "non-VOC: 0-<65 :F" in 1
replace risk_labels = "non-VOC: 0-<65 :M" in 2
replace risk_labels = "non-VOC: 65-<75 :F" in 3
replace risk_labels = "non-VOC: 65-<75 :M" in 4
replace risk_labels = "non-VOC: 75-<85 : F" in 5
replace risk_labels = "non-VOC: 75-<85 : M" in 6
replace risk_labels = "non-VOC: 85+ : F" in 7
replace risk_labels = "non-VOC: 85+ : M" in 8

replace risk_labels = "VOC: 0-<65 :F" in 9
replace risk_labels = "VOC: 0-<65 :M" in 10
replace risk_labels = "VOC: 65-<75 :F" in 11
replace risk_labels = "VOC: 65-<75 :M" in 12
replace risk_labels = "VOC: 75-<85 : F" in 13
replace risk_labels = "VOC: 75-<85 : M" in 14
replace risk_labels = "VOC: 85+ : F" in 15
replace risk_labels = "VOC: 85+ : M" in 16

replace risk_labels = "non-VOC: None" in 17
replace risk_labels = "non-VOC: 1" in 18
replace risk_labels = "non-VOC: 2+" in 19

replace risk_labels = "VOC: None" in 20
replace risk_labels = "VOC: 1" in 21
replace risk_labels = "VOC: 2+" in 22

noi disp "ABSOLUTE RISK ESTIMATES"
list risk_labels risk r_lb r_ub in 1/22



***********************
/* Subgroup analyses */
***********************

/* Fully adjusted OR - age grouped, cat hh size */

glm risk_28 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week care_home_type ///
			if eth2 != 6 ///
			, family(bin) link(logit) eform
			
est store e_no_int

* Constant VOC effect over subgroups
lincom 1.sgtf, eform
margins sgtf


/* Age group */
glm risk_28 i.sgtf##ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week care_home_type ///
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
			ib1.hh_total_cat i.region ib1.rural_urban5 ib1.start_week care_home_type///
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
			ib1.hh_total_cat i.region ib1.rural_urban5 ib1.start_week care_home_type ///
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
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat ib1.start_week care_home_type///
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
			ib1.hh_total_cat i.region ib1.rural_urban5 ib0.comorb_cat care_home_type ///
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
			ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week care_home_type ///
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

glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3, ///
			family(bin) link(logit) eform

* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced


* Age grouped
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA, ///
			family(bin) link(logit) eform

* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced


* With region
glm risk_28 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.region, ///
			family(bin) link(logit) eform


* Adjusted absolute odds
margins sgtf
margins sgtf, asbalanced



log close