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
*	Other output:	an_risk_models.log containing:
*					1-Unadjusted RR and absolute risks for SGTF
*					2-Adjusted RR and absolute risks for SGTF
*					3-Subgroup analyses of RR and absolute risk
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

* Absolute risk
margins sgtf



*********************************************************************
/* Demographically adjusted RR - age as spline, continuous hh size */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth5 household_size ///
			i.stp ib1.rural_urban5 ib1.start_week age1 age2 age3, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced



*********************************************************************
/* Demographically adjusted RR - age grouped, cat hh size		   */
/* Not adjusting for comorbidities, obesity, or smoking	status	   */
*********************************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth5 ib1.hh_total_cat ///
			i.stp ib1.rural_urban5 ib1.start_week i.agegroup, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced



***********************************************************
/* Fully adjusted RR - age as spline, continuous hh size */
***********************************************************

glm risk_28 i.sgtf i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat household_size ///
			i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week age1 age2 age3, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced



**************************************************
/* Fully adjusted RR - age grouped, cat hh size */
**************************************************

glm risk_28 i.sgtf i.agegroup i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform


* Adjusted absolute risk
margins sgtf
margins sgtf, asbalanced



***********************
/* Subgroup analyses */
***********************

/* Fully adjusted RR - age grouped, cat hh size */

glm risk_28 i.sgtf i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform
			
est store e_no_int

* Constant VOC effect over subgroups
lincom 1.sgtf, eform
margins sgtf


/* Age group */
glm risk_28 i.sgtf##i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform
			
est store e_ageX

lrtest e_no_int e_ageX

* Age group VOC vs. non-VOC RR
lincom 1.sgtf, eform						// <50
lincom 1.sgtf + 1.sgtf#2.agegroupA, eform	// 50-<65
lincom 1.sgtf + 1.sgtf#3.agegroupA, eform	// 65-<75
lincom 1.sgtf + 1.sgtf#4.agegroupA, eform	// 75-<85
lincom 1.sgtf + 1.sgtf#5.agegroupA, eform	// 85+

* Age group marginal risks
margins sgtf, over(agegroupA)


/* Ethnicity */
*Figure out missings first


/* Comorbidities */
glm risk_28 i.sgtf##ib0.comorb_cat i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib1.start_week, ///
			family(bin) link(log) eform
			
est store e_comorbX

* Test for interaction
lrtest e_no_int e_comorbX

* Comorbidities VOC vs. non-VOC RR
lincom 1.sgtf, eform						// no comorbs
lincom 1.sgtf + 1.sgtf#1.comorb_cat, eform	// 1 comorb
lincom 1.sgtf + 1.sgtf#2.comorb_cat, eform	// 2+ comorbs

* Comorbidity marginal risks
margins sgtf, over(comorb_cat)


/* IMD */
glm risk_28 i.sgtf##ib1.imd i.agegroup i.male ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform
			
est store e_imdX

* Test for interaction
lrtest e_no_int e_imdX

* IMD VOC vs. non-VOC RR
lincom 1.sgtf, eform				// 1 least deprived
lincom 1.sgtf + 1.sgtf#2.imd, eform	// 2
lincom 1.sgtf + 1.sgtf#3.imd, eform	// 3
lincom 1.sgtf + 1.sgtf#4.imd, eform	// 4
lincom 1.sgtf + 1.sgtf#5.imd, eform	// 5 most deprived

* Epi week marginal risks
margins sgtf, over(imd)



/* Epi week */
glm risk_28 i.sgtf##ib1.start_week i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat i.stp ib1.rural_urban5 ib0.comorb_cat, ///
			family(bin) link(log) eform
			
est store e_weekX

* Test for interaction
lrtest e_no_int e_weekX

* Epi week VOC vs. non-VOC RR
lincom 1.sgtf, eform						// week 1
lincom 1.sgtf + 1.sgtf#2.start_week, eform	// week 2
lincom 1.sgtf + 1.sgtf#3.start_week, eform	// week 3
lincom 1.sgtf + 1.sgtf#4.start_week, eform	// week 4
lincom 1.sgtf + 1.sgtf#5.start_week, eform	// week 5
lincom 1.sgtf + 1.sgtf#6.start_week, eform	// week 6
lincom 1.sgtf + 1.sgtf#7.start_week, eform	// week 7

* Epi week marginal risks
margins sgtf, over(start_week)


/* NHS region */
/* No STP adjustment for these models */

glm risk_28 i.sgtf i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week i.region, ///
			family(bin) link(log) eform
			
est store e_region


glm risk_28 i.sgtf##i.region i.agegroupA i.male ib1.imd ib1.eth5 ib1.smoke_nomiss ib1.obese4cat ///
			ib1.hh_total_cat ib1.rural_urban5 ib0.comorb_cat ib1.start_week, ///
			family(bin) link(log) eform
			
est store e_regionX

* Test for interaction
lrtest e_region e_regionX

* NHS region VOC vs. non-VOC RR
lincom 1.sgtf, eform					// East
lincom 1.sgtf + 1.sgtf#1.region, eform	// East mids
lincom 1.sgtf + 1.sgtf#2.region, eform	// London
lincom 1.sgtf + 1.sgtf#3.region, eform	// North E
lincom 1.sgtf + 1.sgtf#4.region, eform	// North W
lincom 1.sgtf + 1.sgtf#5.region, eform	// South E
lincom 1.sgtf + 1.sgtf#6.region, eform	// South W
lincom 1.sgtf + 1.sgtf#7.region, eform	// West mids
lincom 1.sgtf + 1.sgtf#8.region, eform	// Yorks & Hum

* NHS region marginal risks
margins sgtf, over(region)



log close