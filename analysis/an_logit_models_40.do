********************************************************************************
*
*	Do-file:		an_logit_models_40.do
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
log using ./logs/an_logit_models_40, replace t

clear

/*
use "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\output\cr_analysis_dataset.dta"
*/

use ./output/cr_analysis_dataset.dta

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

noi di "SUBSETTING ON 40-DAY RISK POPULATION"
keep if risk_pop_40==1

tab sgtf risk_40, row



*******************
/* Unadjusted OR */
*******************

glm risk_40 i.sgtf, family(bin) link(logit) eform

* Absolute odds
margins sgtf



**************************************************
/* Fully adjusted OR - age grouped, cat hh size */
**************************************************

glm risk_40 i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
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

file open tablecontent using ./output/table3_abs_risk40.txt, write text replace

file write tablecontent ("Table S3: Absolute risk of death by 40-days") _n _n

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



*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

glm risk_40 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, ///
			family(bin) link(logit) eform



* Age grouped
glm risk_40 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin, ///
			family(bin) link(logit) eform



* With region
glm risk_40 i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 ib2.agegroupA i.home_bin i.region, ///
			family(bin) link(logit) eform




log close



insheet using ./output/table3_abs_risk40.txt, clear
export excel using ./output/table3_abs_risk40.xlsx, replace
