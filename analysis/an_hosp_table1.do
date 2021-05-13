********************************************************************************
*
*	Do-file:		an_hosp_table1.do
*
*	Project:		SGTF CFR
*
*	Programmed by:	Daniel Grint
*					Adapted from household classification (Kevin)
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	Table 1 Cox study population
*
********************************************************************************
*
*	Purpose:		This do-file creates table 1 for patients admitted to hospital
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_hosp_table1, replace t

clear


use ./output/cr_analysis_new.dta



********************************************************************************
*	PROGRAMS TO AUTOMATE TABULATIONS
*
********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table

cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	sum `variable' if `variable' `condition'
	**K Wing additional code to aoutput variable category labels**
	local level=substr("`condition'",3,.)
	local lab: label `variable'Lab `level'
	file write tablecontent (" `lab'") _tab
	
	/*this is the overall column*/
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	/*this loops through groups*/
	forvalues i=0/1{
	cou if sgtf == `i'
	local rowdenom = r(N)
	cou if sgtf == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


* Output one row of table for co-morbidities and meds
* This puts it all on the same row, is rohini's edit

cap prog drop generaterow2 
program define generaterow2
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)5
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=0/1{
	cou if sgtf == `i'
	local rowdenom = r(N)
	cou if sgtf == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


********************************************************************************

/* Explanatory Notes 
defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 
	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 
the number followed by space, brackets, formatted pct, end bracket and then tab
the format %3.1f specifies length of 3, followed by 1 dp. 
*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition("== 12")
	
end


********************************************************************************

/* Explanatory Notes 
defines program tabulate variable 
syntax is : 
	- a VARNAME which you stick in variable 
	- a numeric minimum 
	- a numeric maximum 
	- optional missing option, default value is . 
forvalues lowest to highest of the variable, manually set for each var
run the generate row program for the level of the variable 
if there is a missing specified, then run the generate row for missing vals
*/ 

********************************************************************************
* Generic code to qui summarize a continous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontent ("Mean (SD)") _tab 
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=0/1{							
	qui summarize `variable' if sgtf == `i', d
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontent _n

	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=0/1{
	qui summarize `variable' if sgtf == `i', d
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontent _n
	
end



********************************************************************************
* INVOKE PROGRAMS FOR TABLE 1 
*
********************************************************************************

* DROP MISSING UTLA
noi di "DROPPING MISSING UTLA DATA"
drop if utla_group==""

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0

noi di "SUBSETTING ON COX POPULATION"
keep if cox_pop==1

noi di "SUBSETTING ON HOSPITAL ADMISSIONS"
keep if end_death_hosp != .


*Set up output file
cap file close tablecontent

file open tablecontent using ./output/table1_hosp.txt, write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

file write tablecontent _tab ("Total")		_tab ///
							 ("non-VOC")	_tab ///
							 ("VOC")		_n
							 


* DEMOGRAPHICS (more than one level, potentially missing) 

/*reminder of variables:
patient_id age ageCat hh_id hh_size hh_composition case_date case eth5 eth16 ethnicity_16 indexdate sex bmicat smoke imd region comorb_Neuro comorb_Immunosuppression shielding chronic_respiratory_disease chronic_cardiac_disease diabetes chronic_liver_disease cancer egfr_cat hypertension smoke_nomiss rural_urban
*/

*HOSPTIAL ADMISSION
label define end_hosp_testLab 1 "N"
label values end_hosp_test end_hosp_testLab
tabulatevariable, variable(end_hosp_test) min(1) max(1) 
file write tablecontent _n

*ICU ADMISSION
tabulatevariable, variable(end_icu_test) min(0) max(1) 
file write tablecontent _n

*DIED
tabulatevariable, variable(cox_death) min(0) max(1) 
file write tablecontent _n

*DEATH|HOSP
tabulatevariable, variable(end_death_hosp) min(0) max(1) 
file write tablecontent _n

*TIME TO DEATH
summarizevariable, variable(cox_time_d) 
file write tablecontent _n

*FOLLOW-UP TIME
summarizevariable, variable(cox_time) 
file write tablecontent _n

*EPI WEEK
tabulatevariable, variable(start_week) min(1) max(8) 
file write tablecontent _n 

*SEX
tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n 

*AGE
summarizevariable, variable(age) 
file write tablecontent _n

tabulatevariable, variable(agegroup) min(0) max(7) 
file write tablecontent _n 

*ETHNICITY
tabulatevariable, variable(eth5) min(1) max(6) 
file write tablecontent _n 

*BMI
tabulatevariable, variable(obese4cat) min(1) max(4) 
file write tablecontent _n 

*SMOKING
tabulatevariable, variable(smoke_nomiss) min(1) max(3) 
file write tablecontent _n

*COMORBIDITIES (3 CATEGORIES)
tabulatevariable, variable(comorb_cat) min(0) max(2) 
file write tablecontent _n

*IMD
tabulatevariable, variable(imd) min(1) max(5) 
file write tablecontent _n 

*HOUSEHOLD SIZE
replace hh_total_cat = 5 if hh_total_cat==.
label define hh_total_catLab 5 "Missing", modify
tabulatevariable, variable(hh_total_cat) min(1) max(5) 
file write tablecontent _n 

*CARE HOME
tabulatevariable, variable(home_bin) min(0) max(1) 
file write tablecontent _n 

*REGION
tabulatevariable, variable(region) min(0) max(8) 
file write tablecontent _n 

*RURAL URBAN (five categories)
replace rural_urban5 = 6 if rural_urban5==.
label define rural_urban5Lab 6 "Missing", modify
tabulatevariable, variable(rural_urban5) min(1) max(6) 
file write tablecontent _n 



file write tablecontent _n _n


file close tablecontent



/* Histogram of time to death */

twoway (histogram cox_time_d if sgtf==0, color(red%30)) ///        
       (histogram cox_time_d if sgtf==1, color(blue%30)), ///   
       legend(order(1 "non-VOC" 2 "VOC" ))

graph export ./output/time_death_hosp.svg, as(svg) replace



* Close log file 
log close

clear

insheet using ./output/table1_hosp.txt, clear

export excel using ./output/table1_hosp.xlsx, replace

