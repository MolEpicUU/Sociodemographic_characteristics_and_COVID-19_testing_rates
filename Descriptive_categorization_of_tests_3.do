preserve
local CNImed=0.9694 //from weighted table1
drop if postnummer==75460
merge n:1 Provtatgningsstation using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Provtagningsstationer_categorized_230822.dta",nogenerate
tostring postnummer,replace
merge n:1 postnummer using "MyData/CNI.dta",nogenerate
gen CNI_cat=1 if CNI>=`CNImed'
replace CNI_cat=0 if CNI<`CNImed'
gen Ålder70=(Ålder>=70)
replace Ålder70=. if Ålder==.
replace Class="Sjukhus" if Class=="Jourmottagning = Sjukhus"
replace Class="Primärvård" if Class=="Smittspårning"
collapse (sum) AntalProv,by(Ålder70 Class CNI_cat)
*drop if Class==""
egen TotalProv=sum(AntalProv),by(Class CNI_cat)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroupCNIIncluded.xlsx",firstrow(variables) replace
collapse (sum) AntalProv,by(Ålder70 Class)
egen TotalProv=sum(AntalProv),by(Class)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroupIncluded.xlsx",firstrow(variables) replace
restore
