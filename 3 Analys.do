/*This is the file where 
1)the regression models are run 
2)plots and data for TRR and marginal effects are created.
3)the difference-in-difference analysis is run
4)The tables with min- and max-TRR per pandemic period is created
*/

clear
clear mata
clear matrix 
set matsize 5000
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear

*global model "distance_cases"
if "$model"!="distance_cases" global outcome "CNI"
if "$model"=="distance_cases" global outcome "Distance"

**********************This is the part for generating the model(s).
//Different models for distance, adj. for hospitalizations and adj. for positive tests.
//The models are slow, so it's worth commenting away the "if"-parts and the "estimate save" once the models have been generated, 
//only running the "estimates use" command
if "$model"=="distance_hosp" | "$model"=="distance_cases"{ 
	drop if date>date("12oct2020","DMY")
	drop date_spl*
	gen date_spl1=date_0
	*if "$model"=="distance_hosp" poisson AntalProv i.agegroup##c.date_spl*##c.CNI##i.Gender##i.area_75 i.agegroup##c.date_spl*##c.Distance##i.Gender##i.area_75 PatSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
	preserve
	drop if agegroup==1 & date<date("01aug2020","DMY")
	*if "$model"=="distance_cases" poisson AntalProv i.agegroup##c.date_spl*##c.CNI##i.Gender##i.area_75 i.agegroup##c.date_spl*##c.Distance##i.Gender##i.area_75 PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
	restore
}
preserve
drop if agegroup==1 & date<date("01aug2020","DMY")
*if "$model"=="crude" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
if "$model"=="hospitalizations" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 PatSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
*if "$model"=="cases" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
restore
*estimates save "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}",replace
estimates use "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}"

**************************************************************
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\p_values_for_TRR_plots.do" //p-values for figures
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\marginal_effects_plots.do" //Figure 2
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\TRR_plots.do" //Figure 3
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Moving average plots and TRR tables.do"


