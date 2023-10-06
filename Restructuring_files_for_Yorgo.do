//The raw data underlying all plots (exported as figure number)
cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData"
import excel "YorgoFig2_cases.xlsx",clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Figure2.xlsx",replace firstrow(variables)
import excel "YorgoFig3_cases.xlsx",clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Figure3.xlsx",replace firstrow(variables)
import excel "YorgoFig4_casesno_case.xlsx",clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Figure4_main.xlsx",replace firstrow(variables)
import excel "YorgoFig4_casescase.xlsx",clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Figure4_with_case_adjustment.xlsx",replace firstrow(variables)

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Tests_hospitalizations_graph1_for_R.dta",clear
export excel "Supplementary_figure4_city.xlsx",replace firstrow(variables)

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Tests_hospitalizations_graph0_for_R.dta",clear
export excel "Supplementary_figure4_county.xlsx",replace firstrow(variables)

import excel YorgoFig2_hospitalizations.xlsx,clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Suppl_figure_7.xlsx",replace firstrow(variables)

import excel YorgoFig2_distance_cases.xlsx,clear firstrow
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "Suppl_figure_8.xlsx",replace firstrow(variables)


clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_11.dta",replace emptyok
import excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata.xlsx",firstrow clear
foreach var in Gottsunda Sävja{
	preserve
	collapse (sum) Antal* pop,by(Cat date)
	keep if Cat=="`var'"
	tsset date
	replace AntalProv=AntalProv/pop*100000
	replace Antalpositiva=Antalpositiva/pop*100000
	
	egen prov_tot_ma7 = filter(AntalProv), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
	egen pos_tot_ma7 = filter(Antalpositiva), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\\`var'_tmp.dta",replace
	restore
}
preserve
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Gottsunda_tmp.dta",clear
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Sävja_tmp.dta"
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_10.xlsx",replace firstrow(variables)
restore

foreach var in Gottsunda Sävja{
	forv i=1/5{
		preserve
		collapse (sum) Antal* pop,by(Cat agegroup date)
		keep if Cat=="`var'" & agegroup==`i'
		tsset date
		replace AntalProv=AntalProv/pop*100000
		replace Antalpositiva=Antalpositiva/pop*100000
		egen prov_tot_ma7 = filter(AntalProv), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
		egen pos_tot_ma7 = filter(Antalpositiva), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\\`var'`i'_tmp.dta",replace
		append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_11.dta"
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_11.dta",replace
		restore
	}
}

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_11.dta",clear
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_11.xlsx",replace firstrow(variables)

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data_stratified_predictions.dta",clear
drop if agegroup==1 & date<date("01aug2020","DMY")
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Review_figure_stratified_model.xlsx",replace firstrow(variables)

//number of tests (ma7) by agegroup
clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_5.dta",replace emptyok
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear
collapse (sum) AntalProv Antalpositiva pop,by(agegroup date Gender area_75)
replace AntalProv=AntalProv/pop*100000
replace Antalpositiva=Antalpositiva/pop*100000
forv i=1/5{
	forv j=1/2{
		forv k=0/1{
			preserve
			keep if agegroup==`i' & Gender==`j' & area_75==`k'
			tsset date
			egen prov_tot_ma7 = filter(AntalProv), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
			egen pos_tot_ma7 = filter(Antalpositiva), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
			append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_5.dta"
			save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_5.dta",replace
			restore
		}
	}
}

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_5.dta",clear
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_5.xlsx",firstrow(variables) replace
