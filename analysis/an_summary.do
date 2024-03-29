********************************************************************************
*
*	Do-file:		an_summary.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	an_summary.log
*					
*
********************************************************************************
*
*	Purpose:		This do-file summarises:
*					1-the number of deaths by SGTF status for each covariate
*					2-plots the proportion of SGTF cases over time by NHS region
*					3-plots the number of hospitalisations over time
*					4-plots the number of ICU admissions over time
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_summary, replace t

clear

/*
use "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\output\cr_analysis_dataset.dta"
*/

use ./output/cr_analysis_new.dta

* Tabulate number of deaths by SGTF and covariates

foreach var of varlist agegroup agegroupA agegroup6 male imd eth5 eth2 smoke_nomiss smoke_nomiss2 ///
			obese4cat hh_total_cat home_bin region rural_urban5 comorb_cat start_week {
			
			noi disp "Table `var'"
			table `var' sgtf, contents(count patient_id sum risk_28 mean risk_28 sum cox_death)	
			}


* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0


* Tabulate number of deaths by SGTF and covariates

foreach var of varlist agegroup agegroupA agegroup6 male imd eth5 eth2 smoke_nomiss smoke_nomiss2 ///
			obese4cat hh_total_cat home_bin region rural_urban5 comorb_cat start_week {
			
			noi disp "Table `var'"
			table `var' sgtf, contents(count patient_id sum risk_28 mean risk_28 sum cox_death)	
			}


* Tabulate number of hosptial admissions by SGTF and covariates

foreach var of varlist agegroup agegroupA agegroup6 male imd eth5 eth2 smoke_nomiss smoke_nomiss2 ///
			obese4cat hh_total_cat home_bin region rural_urban5 comorb_cat start_week {
			
			noi disp "Table `var'"
			table `var' sgtf, contents(count patient_id sum end_hosp_test mean end_hosp_test)	
			}
			

* Tabulate number of ICU admissions by SGTF and covariates

foreach var of varlist agegroup agegroupA agegroup6 male imd eth5 eth2 smoke_nomiss smoke_nomiss2 ///
			obese4cat hh_total_cat home_bin region rural_urban5 comorb_cat start_week {
			
			noi disp "Table `var'"
			table `var' sgtf, contents(count patient_id sum end_icu_test mean end_icu_test)	
			}

			
			
* Plot SGTF proportion by NHS region

/*
clear
import delimited "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\lookups\VOC_Data_England.csv"

gen week_date = date(week, "DMY")
format week_date %td

drop if week_date < date("16nov2020", "DMY")

gen start_week = 10 if week_date <= date("24jan2021", "DMY")
replace start_week = 9 if week_date <= date("17jan2021", "DMY")
replace start_week = 8 if week_date <= date("10jan2021", "DMY")
replace start_week = 7 if week_date <= date("03jan2021", "DMY")
replace start_week = 6 if week_date <= date("27dec2020", "DMY")
replace start_week = 5 if week_date <= date("20dec2020", "DMY")
replace start_week = 4 if week_date <= date("13dec2020", "DMY")
replace start_week = 3 if week_date <= date("06dec2020", "DMY")
replace start_week = 2 if week_date <= date("29nov2020", "DMY")
replace start_week = 1 if week_date <= date("22nov2020", "DMY")

rename percent_confirmedsgtf phe_sgtf
rename n_total phe_n

rename region region_s

gen region=0 if region_s=="East of England"
replace region=1 if region_s=="East Midlands"
replace region=2 if region_s=="London"
replace region=3 if region_s=="North East"
replace region=4 if region_s=="North West"
replace region=5 if region_s=="South East"
replace region=6 if region_s=="South West"
replace region=7 if region_s=="West Midlands"
replace region=8 if region_s=="Yorkshire and Humber"

keep region start_week week phe_sgtf phe_n

save "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\lookups\VOC_Data_England.dta"
*/

/*
* Drop if unknown SGTF
drop if !inrange(sgtf,0,1)

* Calculate % SGTF by week and region
collapse (mean) sgtf (count) patient_id, by(region start_week)

gen os_sgtf = sgtf*100
rename patient_id os_n

* Merge on PHE data
/*
merge 1:1 region start_week using "C:\Users\EIDEDGRI\Documents\GitHub\SGTF-CFR-research\lookups\VOC_Data_England.dta"
*/

merge 1:1 region start_week using ./lookups/VOC_Data_England.dta
sort region start_week

gen week_date = date(week, "DMY")
format week_date %td

label define epi_week	1 "47" 2 "48" 3 "49" 4 "50" 5 "51" 6 "52" 7 "53" 8 "1" 9 "2" 10 "3"
label values start_week epi_week


line phe_sgtf os_sgtf start_week, by(region) ///
	ytitle("% of positive tests with SGTF") ///
	xlabel(1(1)10, valuelabel) ///
	legend(label(1 "PHE") label(2 "TPP"))
graph export ./output/sgtf_perc_region.svg, as(svg) replace
graph export ./output/sgtf_perc_region.pdf, as(pdf) replace
*/

log close

