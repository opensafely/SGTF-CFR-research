********************************************************************************
*
*	Do-file:		cr_imputed.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	output/cr_imputed_dataset.dta
*
*	Other output:	cr_imputed.log
*
*
********************************************************************************
*
*	Purpose:		This do-file imputes missing ethnicity data
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/cr_imputed_new, replace t

clear

use ./output/cr_analysis_new.dta


recode eth2 6=. 5=0
tab eth2, m


egen inc = rowmiss(age1 age2 age3 male obese4cat smoke_nomiss imd comorb_cat region ///
					rural_urban hh_total_cat home_bin sgtf start_week cox_death)
					
keep if inc==0


mi set wide
mi register imputed eth2

mi impute logit eth2				///
			age1 age2 age3 			///
			i.male 					///
			i.obese4cat				///
			i.smoke_nomiss			///
			i.imd 					///
			i.comorb_cat			///
			i.region				///
			i.rural_urban			///
			i.hh_total_cat			///
			i.home_bin				///
			i.sgtf					///
			i.start_week			///
			cox_death, add(10) rseed(13072021) noisily iter(20)
			
			


label data "SGTF CFR NEW IMPUTED DATASET: $S_DATE"

save ./output/cr_imputed_new.dta, replace

log close
