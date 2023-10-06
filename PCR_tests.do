//The resulting dataset has one row for each combination of  postal code, gender, age group and date. Testing variables are aggregated to that level.

*********PROGRAM FOR FLOWCHART (determining number of tests)**********************'
cap program drop Descriptive_Tests
program define Descriptive_Tests,rclass
egen AntalProvTot=sum(AntalProv)
sum AntalProvTot
return scalar N=r(mean)
drop AntalProvTot
end
********************************************************************

cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
putdocx paragraph

*************************************PCR TESTS*************************************************
//Generating one big file of PCR-tests (FirstData)
//Matching five-digit-codes to tests. There can be several rows per five-digit-code, corresponding to date and testing unit
//Only 16+, from June 24th to and including Oct 12th .
if "${All}"=="All"{
	clear
	save "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\ProcessedData\FirstData.dta",replace emptyok
		cd "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\PCR_files_complete"
		local files: dir . files "pcr*xlsx"
		foreach var of local files{
			import excel "`var'",firstrow clear
			gen File="`var' `v2'"
			cap drop Typningsresultat
			forv i=1/15{
				cap drop Analys`i'
			}
			append using "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\ProcessedData\FirstData.dta",force
			save "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\ProcessedData\FirstData.dta",replace
		}
}
use "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\ProcessedData\FirstData.dta",clear
encode Kon,gen(Gender)
*****************************************************************************'

**************************************************************
//THIS IS THE FLOWCHART PART, REMOVING TESTS WITHOUT KNOWN POSTAL CODE, SCREENING, CONTACT TRACING, NON-PATIENT INITIATED ETC
Descriptive_Tests
putdocx paragraph,font(,18)
putdocx text ("FLOWCHART"), linebreak(2)
putdocx paragraph
putdocx text ("Number of tests is `=r(mean)'"), linebreak(1)
rename ZipCode postnummer
replace postnummer=subinstr(postnummer," ","",.)
destring postnummer,replace force
drop if postnummer==.
drop if postnummer==0

Descriptive_Tests
putdocx text ("After keeping only tests with known postal code, number of tests is `=r(N)'"), linebreak(1)

gen tmp=dofc(Provtagningsdatum)
drop Provtagningsdatum
rename tmp date

replace Ålder="0" if Ålder=="<1"
destring Ålder,replace
assert inrange(Ålder,0,105)

gen agegroup=1 if inrange(Ålder,0,14)
replace agegroup=2 if inrange(Ålder,15,29)
replace agegroup=3 if inrange(Ålder,30,49)
replace agegroup=4 if inrange(Ålder,50,69)
replace agegroup=5 if inrange(Ålder,70,105)

replace postnummer=74020 if postnummer==75578 | postnummer==75577 | postnummer==75576 //a postal code (Vänge) which split up into three different codes during the study period.

cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
merge n:1 postnummer date agegroup Gender using "MyData\date_postcode_matrix.dta",keep(match using) //from "Preprocessing.do"
//this is mainly for getting the right postal codes here.

drop _merge
Descriptive_Tests
putdocx text ("After keeping only tests from Uppsala county, number of tests is `=r(N)'"), linebreak(1)

assert date>=date("$start_date","DMY") & date<=date("$end_date","DMY")
Descriptive_Tests
putdocx paragraph
putdocx text ("After keeping only tests from $start_date to $end_date, number of tests is `=r(N)'"), linebreak(1)

tostring postnummer,replace
merge n:1 postnummer using "MyData/CNI.dta",nogenerate keep(match)
destring postnummer,replace

replace Provtatgningsstation="Skutskärs vårdcentral" if strpos(Provtatgningsstation,"Skutskär VC")
replace Provtatgningsstation="Heby vårdcentral" if strpos(Provtatgningsstation,"Heby VC")
replace Provtatgningsstation="Nyby vårdcentral" if strpos(Provtatgningsstation,"Nyby VC")
replace Provtatgningsstation="Tierps vårdcentral" if strpos(Provtatgningsstation,"Tierp VC")
replace Provtatgningsstation="Praktikertjänst Knivsta Läkargrupp" if strpos(Provtatgningsstation,"Praktikertjänst Knivsta")
replace Provtatgningsstation="Östhammars vårdcentral" if strpos(Provtatgningsstation,"Östhammar VC")
replace Provtatgningsstation="Kungsgärdets vårdcentral" if strpos(Provtatgningsstation,"Kungsgärdet VC")
replace Provtatgningsstation="Enköpings husläkarcentrum" if strpos(Provtatgningsstation,"Enköping husläkarcentrum VC")
replace Provtatgningsstation="Gottsunda vårdcentral" if strpos(Provtatgningsstation,"Gottsunda VC")

include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_1.do" //just some descriptives irrelevant for main code

drop if Provtagningsorsak=="Screening" | Provtagningsorsak=="Smittspårning"

Descriptive_Tests
putdocx text ("After removing screening, smittspårning, number of tests is `=r(N)'"),linebreak(1)

gen flag="keep" if (Provtagningsorsak=="Aktuell infektionsmisstanke" | Provtagningsorsak=="Kliniska symtom-egenvård i hemmet" ///
| Provtagningsorsak=="Symtom kvarstår" | Provtagningsorsak=="Åter till arbete" | Analys=="Egenprovtagning-Coronavirus COVID-19(SARS-CoV-2)" ///
| Analys=="Egenprovtagning-Luftvägsvirus (PCR)" | strpos(Analys,"Allmänheten-Coronavirus COVID-19") ///
| Analys=="ÖVRIGA PERSONAL-Coronavirus COVID-19 (SARS CoV 2) PCR" | Analys=="Luftvägsvirus (PCR) Litet block (inkl.SARS-CoV-2)" ///
| Analys=="Allmänheten-Luftvägsvirus (PCR) Litet block (inkl.SARS-CoV-2)")

split Bestallare, parse(" ")

include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_2.do" //more descriptives irrelevant for main code

drop if (Provtagningsorsak=="Kliniska symtom-inneliggande vård")
assert agegroup!=.
drop if Bestallare1=="COVID-19," //993 obs dropped

keep if flag=="keep"
drop flag

keep if inlist(Provtatgningsstation,"Kungsgärdets vårdcentral","Enköpings husläkarcentrum","Beredskapsjouren", ///
"Gottsunda vårdcentral","Praktikertjänst BålstaDoktorn","Beredskapsjour NVH","Tierps vårdcentral","Stenhagens vårdcentral") | ///
inlist(Provtatgningsstation,"Östhammars vårdcentral","Nyby vårdcentral","Praktikertjänst Bålsta","Heby vårdcentral","Praktikertjänst Knivsta Läkargrupp", ///
"Skutskärs vårdcentral","Aleris Närakut") | strpos(Provtatgningsstation,"Mobila Provtagningsenheten, Beredskap")

Descriptive_Tests
putdocx text ("After dropping non-patient-initiated tests, the number of tests is `=r(N)'"), linebreak(1)
***************************************************
keep if inrange(Ålder,5,105)
Descriptive_Tests
putdocx text ("after making exklusions for ages below 5 and above 105, number of tests is `=r(N)'"), linebreak(1)

drop if Ålder<16 & date<date("01aug2020","DMY")
Descriptive_Tests
putdocx text ("After dropping ages below 16 if date is earlier than 01aug2020: `=r(N)'"), linebreak(1)

drop if Ålder<9 & date<date("22feb2021","DMY")
Descriptive_Tests
putdocx text ("After dropping ages below 9 if date is earlier than 22feb2021: `=r(N)'"), linebreak(1)

putdocx pagebreak

assert inrange(Antalejklar,0,1)
assert inrange(AntalProv,1,2)
assert inrange(Antalpositivaprov,0,2)

include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_3.do" //more descriptives irrelevant for main code
*****************************************************************************************************************************************************

***************************************Testing per class (hospital, primary care etc)
keep postnummer Antal* date agegroup Gender Ålder
assert inrange(Ålder,5,105)
drop Ålder
collapse (sum) Antal*,by(Gender agegroup date postnummer)
//we want to have rows for every combination of postal code, date, agegroup, Gender, also the zero ones!
merge 1:1 postnummer date agegroup Gender using "MyData\date_postcode_matrix.dta",keep(match using) //this time for getting all dates represented, even if no tests are taken that date for a specific subgroup
replace AntalProv=0 if _merge==2 //zero tests if only in using dataset
replace Antalpositivaprov=0 if _merge==2
replace Antalejklar=0 if _merge==2
drop _merge

save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",replace

unique postnummer
local N=`=r(unique)'

foreach var in enkoping tierp osthammar uppsala{
	import delimited "OriginalData\\`var'_distance_from_test_center_to_postcode.csv", varnames(1) clear 
	replace postcode=subinstr(postcode," ","",.)
	tab postcode if real(postcode)==.
	destring postcode,replace force
	rename postcode postnummer
	replace distance_driving=subinstr(distance_driving,"km","",.)
	destring distance_driving,replace
	rename distance_driving distance_driving_`var'
	save "MyData\\`var'.dta",replace
	merge 1:n postnummer using "MyData/MainData${Sensitivity}.dta",nogenerate keep(match) //OK to use "match" - see assertion at the end of the file
	drop center_location
	save "MyData/MainData${Sensitivity}.dta",replace
}

unique postnummer
assert `=r(unique)'==`N' //asserting that no postal codes are dropped after matching with the distance files

count
assert `=r(N)'==(596*2*5*350) //the number of rows should equal number of days * number of genders * number of agegroups * number of postal codes

fillin Gender agegroup date postnummer //asserting that every combination exists in the dataset
assert _fillin==0
drop _fillin
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData${Sensitivity}.dta",replace
//The file we've now created has one row per postal code, gender, agegroup and date
//relevant postal code level variables are added to the file in "1 Cleaning 20211130"

