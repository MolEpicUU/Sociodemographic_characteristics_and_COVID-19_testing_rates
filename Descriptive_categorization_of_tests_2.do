//This is for classification of PCR tests into different categories depending on where they have been taken.
//(after dropping "screening/smittspårning")
preserve
local CNImed=0.9694 //from weighted table1
keep if flag!="keep" | Provtagningsorsak=="Kliniska symtom-inneliggande vård" | Bestallare1=="COVID-19," | !(inlist(Provtatgningsstation,"Kungsgärdets vårdcentral","Enköpings husläkarcentrum","Beredskapsjouren", ///
"Gottsunda vårdcentral","Praktikertjänst BålstaDoktorn","Beredskapsjour NVH","Tierps vårdcentral","Stenhagens vårdcentral") | ///
inlist(Provtatgningsstation,"Östhammars vårdcentral","Nyby vårdcentral","Praktikertjänst Bålsta","Heby vårdcentral","Praktikertjänst Knivsta Läkargrupp", ///
"Skutskärs vårdcentral","Aleris Närakut") | strpos(Provtatgningsstation,"Mobila Provtagningsenheten, Beredskap"))
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
*drop if Class==""
egen TotalProv=sum(AntalProv),by(Class CNI_cat)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroupCNI_96688.xlsx",firstrow(variables) replace
collapse (sum) AntalProv,by(Ålder70 Class)
egen TotalProv=sum(AntalProv),by(Class)
gen Ålder_perc=AntalProv/TotalProv
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ProvtagningByGroup_96688.xlsx",firstrow(variables) replace
restore
