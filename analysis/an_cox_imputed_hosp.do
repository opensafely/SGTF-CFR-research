********************************************************************************
*
*	Do-file:		an_cox_imputed.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_imputed_dataset.dta
*
*	Data created:	output/an_imputed_eth5
*					output/an_imputed_eth2
*
*	Other output:	an_cox_imputed.log
*
*
********************************************************************************
*
*	Purpose:		This do-file imputes missing ethnicity data
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_cox_imputed_hosp, replace t

clear


use ./output/cr_imputed_hosp.dta

* DROP MISSING UTLA
noi di "DROPPING MISSING UTLA DATA"
drop if utla_group==""

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

noi di "SUBSETTING ON COX CENSORED POPULATION"
keep if cox_pop==1

tab sgtf end_hosp_test, row


* Declare survival data
mi stset stime_hosp_test, origin(study_start) fail(end_hosp_test) scale(1) id(patient_id)


* Stratified by region
mi estimate, eform: stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 , strata(utla_group)
			 
estimates save ./output/an_imputed_eth2_hosp, replace



log close
