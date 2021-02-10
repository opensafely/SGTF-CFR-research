********************************************************************************
*
*	Do-file:		an_risk_models.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file runs risk models, calculating relative (glm) and
*					absolute risk (margins)
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_risk_models, replace t

clear

/*
use "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\output\cr_analysis_dataset.dta"
*/

use ./output/cr_analysis_dataset.dta

noi di "SUBSETTING ON 28-DAY RISK POPULATION"
keep if risk_pop==1

tab sgtf risk_28, row


*******************
/* Unadjusted RR */
*******************

glm risk_28 i.sgtf, family(bin) link(log) eform

/*
predict pred_xb if e(sample), xb
predict pred_se if e(sample), stdp

gen ln_lb = pred_xb - invnormal(0.975)*pred_se
gen ln_ub = pred_xb + invnormal(0.975)*pred_se

gen xb = exp(pred_xb)
gen lb = exp(ln_lb)
gen ub = exp(ln_ub)
*/

* Absolute risk
margins sgtf



***********************************************************
/* Fully adjusted RR - age as spline, continuous hh size */
***********************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat household_size ///
			i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced

*margins male imd eth5 smoke_nomiss obese4cat rural_urban5 comorb_cat, at(sgtf=(0 1))



**************************************************
/* Fully adjusted RR - age grouped, cat hh size */
**************************************************

glm risk_28 i.sgtf i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced


log close