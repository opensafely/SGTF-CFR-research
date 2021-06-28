********************************************************************************
*
*	Do-file:		an_cox_deathhosp.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_new.dta
*
*	Data created:	
*
*	Other output:	an_cox_hosp.log containing:
*					1-Unadjusted Cox models for SGTF
*					2-Adjusted Cox models for SGTF
*
********************************************************************************
*
*	Purpose:		This do-file runs Cox PH models, calculating HR for VOC 
*					vs. non-VOC for death given hospital admission
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_cox_deathhosp, replace t

clear

use ./output/cr_analysis_new.dta


* DROP MISSING UTLA
noi di "DROPPING MISSING UTLA DATA"
drop if utla_group==""

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

noi di "SUBSETTING ON COX CENSORED POPULATION"
keep if cox_pop==1

noi di "SUBSETTING ON HOSPITALISED POPULATION"
keep if end_death_hosp != .

tab sgtf end_death_hosp, row


*Set up output file
cap file close tablecontent

file open tablecontent using ./output/table2_hr_deathhosp.txt, write text replace

file write tablecontent ("Table 2: Hazard ratios for VOC vs. non-VOC") _n _n

file write tablecontent ("Estimate")	_tab ///
						("HR (95% CI)")	_tab ///
						("P-value")		_n


*******************
/* Unadjusted HR */
*******************

stset time_death_hosp, fail(end_death_hosp) scale(1) id(patient_id)

stcox i.sgtf

* Stratified by STP
stcox i.sgtf, strata(stp)

* Stratified by region
stcox i.sgtf, strata(region)

* Stratified by UTLA
stcox i.sgtf, strata(utla_group)

* N (events)
tab sgtf end_death_hosp if e(sample)

* Output unadjusted
lincom 1.sgtf, eform
file write tablecontent _n ("Unadjusted") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Interaction with time
stcox i.sgtf, tvc(i.sgtf) strata(utla_group)

/*
* Interaction with time excluding November
stcox i.sgtf if study_start >= date("01dec2020", "DMY"), strata(utla_group)
estat phtest, d

stcox i.sgtf if study_start >= date("01dec2020", "DMY"), tvc(i.sgtf) strata(utla_group)
*/


************************
/* Age as spline only */
************************

* Stratified by region
stcox i.sgtf age1 age2 age3 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Age adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

/*
* Age grouped only
stcox i.sgtf ib2.agegroupA ///
			 , strata(utla_group)
*/


***************************
/* Age and comorbidities */
***************************

* Stratified by region
stcox i.sgtf age1 age2 age3 ib0.comorb_cat ib1.smoke_nomiss2 ib1.obese4cat ///
			 , strata(utla_group)
		 
* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Age + comorb adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



*********************************************************************
/* Demographically adjusted HR - age as spline, cat hh size 	   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat i.home_bin ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Demographically adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


			 
*********************************************************************
/* Demographically adjusted HR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

/*
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.hh_total_cat i.home_bin ///
			 ib1.rural_urban5 ib1.start_week ib2.agegroupA ///
			 if eth2 != 6 ///
			 , strata(utla_group)
*/

			 
****************************************************
/* Fully adjusted HR - age as spline, cat hh size */
****************************************************

* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_no_int

* N (events)
tab sgtf end_death_hosp if e(sample)
bysort start_weekA: tab sgtf end_death_hosp if e(sample)
bysort comorb_cat: tab sgtf end_death_hosp if e(sample)
bysort eth2: tab sgtf end_death_hosp if e(sample)
bysort imd: tab sgtf end_death_hosp if e(sample)
bysort agegroupA: tab sgtf end_death_hosp if e(sample)

estat phtest, d


lincom 1.sgtf, eform
file write tablecontent ("Fully adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

* Plot scaled schoenfeld residuals
estat phtest, plot(1.sgtf)
graph export ./output/cox_shoen_deathhosp.svg, as(svg) replace

/*
* KM plot
sts graph,	surv by(sgtf) ci risktable(, order(1 "non-VOC" 2 "VOC") size(small)) ///
			ylabel(0.994(0.001)1, format(%5.3f)) ///
			legend(order(2 4) label(2 "non-VOC") label(4 "VOC") rows(1))
graph export ./output/cox_km.svg, as(svg) replace

* Cumulative hazard plot
sts graph,	cumhaz by(sgtf) ci ///
			ylabel(minmax, format(%5.3f)) ///
			legend(order(2 4) label(2 "non-VOC") label(4 "VOC") rows(1))
graph export ./output/cox_cumhaz.svg, as(svg) replace
*/
	
* Smoothed hazard plot
sts graph,	haz by(sgtf) ///
			legend(label(1 "non-VOC") label(2 "VOC"))
graph export ./output/cox_haz_deathhosp.svg, as(svg) replace


/* Subgroup analyses */

* Epi week
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib2.start_weekA age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_week


stcox i.sgtf##ib2.start_weekA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_weekX

* Test for interaction
lrtest e_week e_weekX

file write tablecontent _n ("Subgroup analyses") _n 

file write tablecontent _n ("Epi. week") _tab _tab %6.4f (r(p)) _n

* Epi week VOC vs. non-VOC HR
lincom 1.sgtf + 1.sgtf#2.start_weekA, eform	// week 1/2
file write tablecontent ("16Nov-29Nov") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#3.start_weekA, eform	// week 3
file write tablecontent ("30Nov-06Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#4.start_weekA, eform	// week 4
file write tablecontent ("07Dec-13Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#5.start_weekA, eform	// week 5
file write tablecontent ("14Dec-20Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#6.start_weekA, eform	// week 6
file write tablecontent ("21Dec-27Dec") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#7.start_weekA, eform	// week 7
file write tablecontent ("28Dec-03Jan") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#8.start_weekA, eform	// week 8
file write tablecontent ("04Jan-11Jan") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



* Comorbidities
stcox i.sgtf##ib0.comorb_cat i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_comorbX

* Test for interaction
lrtest e_no_int e_comorbX

file write tablecontent _n ("Comorbidities") _tab _tab %6.4f (r(p)) _n

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

* Test for trend
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 c.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_linco

stcox i.sgtf##c.comorb_cat i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_lincoX

lrtest e_linco e_lincoX
local lin_lr_p = r(p)

lincom 1.sgtf#c.comorb_cat, eform
file write tablecontent ("Per unit increase") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (`lin_lr_p') _n



* Ethnicity
stcox i.sgtf##ib1.eth2 i.male ib1.imd ib0.comorb_cat ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_eth2X

* Test for interaction
lrtest e_no_int e_eth2X

file write tablecontent _n ("Ethnicity") _tab _tab %6.4f (r(p)) _n

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



* IMD
stcox i.sgtf##ib1.imd i.male ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib1.start_week ib0.comorb_cat age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)

est store e_imdX

* Test for interaction
lrtest e_no_int e_imdX

file write tablecontent _n ("IMD") _tab _tab %6.4f (r(p)) _n

* IMD VOC vs. non-VOC HR
lincom 1.sgtf, eform						// 1
file write tablecontent ("1 Least deprived") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#2.imd, eform	// 2
file write tablecontent ("2") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#3.imd, eform	// 3
file write tablecontent ("3") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#4.imd, eform	// 4
file write tablecontent ("4") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n

lincom 1.sgtf + 1.sgtf#5.imd, eform	// 5
file write tablecontent ("5 Most deprived") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



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

file write tablecontent _n ("Age group") _tab _tab %6.4f (r(p)) _n

* Age group VOC vs. non-VOC HR
lincom 1.sgtf + 1.sgtf#1.agegroupA, eform	// 0-<65
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


* Test for trend
stcox i.sgtf c.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_cage

stcox i.sgtf##c.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
est store e_cageX

lrtest e_cage e_cageX
local lin_age_p = r(p)

lincom 1.sgtf#c.agegroupA, eform
file write tablecontent ("Per group increase") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (`lin_age_p') _n


**************************
/* Sensitivity analyses */
**************************

* Include with 28-days follow-up
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & risk_pop==1 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)

file write tablecontent _n ("Sensitivity analyses") _n

lincom 1.sgtf, eform
file write tablecontent ("Min. 28-days follow-up") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Include with 40-days follow-up
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & risk_pop_40==1 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Min. 40-days follow-up") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* No adjustment for care home
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib2.start_week age1 age2 age3 ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("No care home adj.") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* NHS England coverage - exclude SE and NE
* Stratified by region
stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 & !inlist(region,3,5) ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf end_death_hosp if e(sample)
tab region if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Exluding NE/SE") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Discharge as censor
stset time_comp_death, fail(comp_death_hosp) scale(1) id(patient_id)

stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
			 
* N (events)
tab sgtf comp_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Censor at hospital discharge") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n



**************************************************
/* Fully adjusted HR - age grouped, cat hh size */
**************************************************

/*
* Stratified by region
stcox i.sgtf ib2.agegroupA i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ///
			 ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)
*/		 
			 
			 
*********************************************************************
/* Causal min adjustment set - age as spline, comorbidities,	   */
/* deprivation index, and smoking status						   */
*********************************************************************

stset time_death_hosp, fail(end_death_hosp) scale(1) id(patient_id)

*stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin

* Stratified by STP
*stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, strata(stp)
			 
* Stratified by region
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss2 age1 age2 age3 i.home_bin, strata(utla_group)

* N (events)
tab sgtf end_death_hosp if e(sample)

lincom 1.sgtf, eform
file write tablecontent ("Causal min. adjustment") _tab 
file write tablecontent %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") _tab %6.4f (r(p)) _n


* Interaction with time
stcox i.sgtf i.comorb_cat ib1.imd i.smoke_nomiss age1 age2 age3 ///
			 if eth2 != 6 ///
			 , strata(utla_group) tvc(i.sgtf)
			 
			 
			 
* Time from positive test
stset time_death_hosp1, fail(end_death_hosp) scale(1) id(patient_id)

stcox i.sgtf i.male ib1.imd ib1.eth2 ib1.smoke_nomiss2 ib1.obese4cat ib1.hh_total_cat ///
			 ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3 i.home_bin ///
			 if eth2 != 6 ///
			 , strata(utla_group)


* Close output table
file write tablecontent _n _n
file close tablecontent
			 

			 
log close


clear

insheet using ./output/table2_hr_deathhosp.txt, clear
export excel using ./output/table2_hr_deathhosp.xlsx, replace

