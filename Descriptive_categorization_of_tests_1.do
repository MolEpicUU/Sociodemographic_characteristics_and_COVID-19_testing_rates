//This is for classification of PCR tests into different categories depending on where they have been taken.
//(before dropping "screening/smittspårning")
preserve
gen Keep="Yes" if inlist(Provtatgningsstation,"Kungsgärdets vårdcentral","Enköpings husläkarcentrum","Beredskapsjouren", ///
"Gottsunda vårdcentral","Praktikertjänst BålstaDoktorn","Beredskapsjour NVH","Tierps vårdcentral","Stenhagens vårdcentral") | ///
inlist(Provtatgningsstation,"Östhammars vårdcentral","Nyby vårdcentral","Praktikertjänst Bålsta","Heby vårdcentral","Praktikertjänst Knivsta Läkargrupp", ///
"Skutskärs vårdcentral","Aleris Närakut") | strpos(Provtatgningsstation,"Mobila Provtagningsenheten, Beredskap")
egen Prov=sum(AntalProv),by(Provtatgningsstation)
keep Provtatgningsstation Keep Prov
duplicates drop
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Provtagningsstation.xlsx",firstrow(variables) replace
restore

preserve
local CNImed=0.9694 //from weighted table1
merge n:1 Provtatgningsstation using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Provtagningsstationer_categorized_230822.dta",nogenerate
tostring postnummer,replace
merge n:1 postnummer using "MyData/CNI.dta",nogenerate
sum CNI,det
gen CNI_cat=1 if CNI>=`CNImed'
replace CNI_cat=0 if CNI<`CNImed'
gen Ålder70=(Ålder>=70)
replace Ålder70=. if Ålder==.
replace Class="Sjukhus" if Class=="Jourmottagning = Sjukhus"
replace Class="Primärvård" if Class=="Smittspårning"
collapse (sum) AntalProv,by(Ålder70 Class CNI_cat)
egen TotalProv=sum(AntalProv),by(Class CNI_cat)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroupCNI.xlsx",firstrow(variables) replace
collapse (sum) AntalProv,by(Ålder70 Class)
egen TotalProv=sum(AntalProv),by(Class)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroup.xlsx",firstrow(variables) replace
restore

preserve
keep if Provtagningsorsak=="Screening" | Provtagningsorsak=="Smittspårning"
merge n:1 Provtatgningsstation using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Provtagningsstationer_categorized_230822.dta",nogenerate
tostring postnummer,replace
merge n:1 postnummer using "MyData/CNI.dta",nogenerate
sum CNI,det
gen CNI_cat=1 if CNI>=`CNImed'
replace CNI_cat=0 if CNI<`CNImed'
gen Ålder70=(Ålder>=70)
replace Ålder70=. if Ålder==.
replace Class="Sjukhus" if Class=="Jourmottagning = Sjukhus"
replace Class="Primärvård" if Class=="Smittspårning"
collapse (sum) AntalProv,by(Ålder70 Class CNI_cat)
egen TotalProv=sum(AntalProv),by(Class CNI_cat)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroupCNI_scr_smi.xlsx",firstrow(variables) replace
collapse (sum) AntalProv,by(Ålder70 Class)
egen TotalProv=sum(AntalProv),by(Class)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroup_scr_smi.xlsx",firstrow(variables) replace
restore
