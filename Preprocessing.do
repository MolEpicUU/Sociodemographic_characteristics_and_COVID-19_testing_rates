//This code merges and appends the datasets from SCB about postcode level attributes (education, income etc.) with test data from hospitals, data about postcode population
//and info about hospitalizations for each postcode.
//The resulting dataset has one row for each combination of  postal code, gender, age group and date. Testing variables are aggregated to that level.

***********************GLOBAL SETTINGS (can be modified by user)****************************
if "$model"=="distance" global All "All" //entire preprocessing code, even slow-running parts if "all"
if "$model"!="distance" global All "All" //entire preprocessing code, even slow-running parts if "all"
global start_date="24jun2020"
global end_date="09feb2022"
***************************************************************

*********PROGRAM FOR FLOWCHART (determining number of tests)**********************'
cap program drop Descriptive_Tests
program define Descriptive_Tests,rclass
cap drop AntalProvTot
egen AntalProvTot=sum(AntalProv)
sum AntalProvTot
return scalar N=r(mean)
end
********************************************************************

cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
putdocx paragraph

******************************POSTAL CODES********************************************************
//Population per sex and age group for five-digit-codes. This is used for creating hospitalizations/capita.
import delimited "OriginalData\pop_5digitpost_sex_age_clean_nonsensitive.csv", clear delimiter(";")
rename five_digit postnummer
destring postnummer, force replace
keep postnummer
duplicates drop
save "MyData\populated_postnummer.dta", replace
****************************************************************************************************************

**************************************CREATE MATRIX WITH POSTAL CODES PER DATE, GENDER, AGEGROUP************
//This part of the code extracts the postal numbers in Uppsala county. It creates two datasets, one with
//only the postal codes, one with every combination of postal code, date, gender and agegroup. The point is that the PCR-test-dataset will not
//have all these combinations, and we need them (to put a 0 in the "test" column for the missing combinations)
import excel "OriginalData\Postnummerservice_postcode_lan_kommun.xls", sheet("Sheet1") firstrow clear
keep if Länskod=="03" //remove postal codes not in uppsala

//n=533 postnummer

keep Postnummer
rename Postnummer postnummer
destring postnummer,replace
duplicates drop
merge 1:1 postnummer using "MyData\populated_postnummer.dta",nogenerate keep(match) //ensuring we only keep populated postal codes within Uppsala

//n=361 postnummer

//asserting that the file contains the old Vänge postal code, not the three new ones.
assert postnummer!=75578 & postnummer!=75577 & postnummer!=75576 
cap assert postnummer!=74020
if _rc==0 postnummer 74020 saknas!

tostring postnummer,replace
//postal codes mostly overlapping with other counties
drop if inlist(postnummer,"73391","73392","73398","19592","19593")
drop if inlist(postnummer,"64593","72596","76295","76296","76297")

destring postnummer,replace
count
local N=r(N)  
//creates a matrix containing a combination of each postal code, date, gender and agegroup
keep postnummer
local Diff=(date("$end_date","DMY")+1)-date("$start_date","DMY")
expand `Diff'
gen date=date("$start_date","DMY")
bysort postnummer: replace date=date+(_n-1) if postnummer==postnummer[_n-1]
expand 5
bysort postnummer date: gen agegroup=_n
expand 2
bysort postnummer date agegroup: gen Gender=_n
isid postnummer agegroup Gender date
cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\"
save "MyData\date_postcode_matrix.dta",replace
keep postnummer
duplicates drop
save "MyData\postcode_matrix.dta",replace
*************************************************************

putdocx paragraph

********************************SCB FILES*****************************************************
//Here files from SCB about gender, age, foreign background, employment etc. on postal code level are processed and stored as "Employment.dta", "Utomlands.dta"
//It also contains a code for generating class
include "Codes\1b Cleaning_programs.do" //extracting postal code populations and % women per postal code for merging with main file

if "${All}"=="All"{ 
	import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Toves cleaning scripts and temp files\infiles\stadsdel_update.xlsx",firstrow clear //file matching postal code to suburb/city area in Uppland.
	save "MyData\stadsdel.dta",replace
}
*************************************************************************************'

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

*******************************FILES USED TO GENERATE DATA****************
drop if Provtagningsvecka=="" //för att få bort "summa"-kolumnerna i varje fil
egen AntalProvTot=sum(AntalProv)
sum AntalProvTot
putdocx paragraph,font(,18)
putdocx text ("Files used to generate data:"), linebreak(2)
putdocx paragraph
putdocx text ("enkoping_distance_from_test_center_to_postcode.csv"), linebreak(1)
putdocx text ("uppsala_distance_from_test_center_to_postcode.csv"), linebreak(1)
putdocx text ("tierp_distance_from_test_center_to_postcode.csv"), linebreak(1)
putdocx text ("osthammar_distance_from_test_center_to_postcode.csv"), linebreak(1)
putdocx text ("PCR-files in the folder Hospital_UU\PCR_files_complete\PCR_files_complete (.xlsx)"), linebreak(1)
putdocx text ("SCB\PostnrStatistik_Alla tabeller.xlsx"), linebreak(1)
putdocx text ("CNI efter postnr_2020.xlsx"), linebreak(1)
putdocx text ("SCB\leverans20210621\UU_Postnummer202103.xlsx"), linebreak(1)
putdocx text ("Toves cleaning scripts and temp files\infiles\stadsdel_update.xlsx"), linebreak(1)
putdocx text ("CRUSH_Covid\Hospital_UU\PCR_files_complete\Vaccine (.xlsx files)"), linebreak(1)
putdocx text ("CRUSH_Covid\Hospital_UU\CRUSH 06\sjukhus inskrivna.xlsx"),linebreak(2)
*********************************************************************

**************************************************************
//THIS IS THE FLOWCHART PART, REMOVING TESTS WITHOUT KNOWN POSTAL CODE, SCREENING, CONTACT TRACING, NON-PATIENT INITIATED ETC
putdocx paragraph,font(,18)
putdocx text ("FLOWCHART"), linebreak(2)
putdocx paragraph
putdocx text ("Number of tests is `=r(mean)'"), linebreak(1)
drop AntalProvTot
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

cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
merge n:1 postnummer date agegroup Gender using "MyData\date_postcode_matrix.dta",keep(match using) 

drop _merge
Descriptive_Tests
putdocx text ("After keeping only tests from Uppsala county, number of tests is `=r(N)'"), linebreak(1)

replace postnummer=74020 if postnummer==75578 | postnummer==75577 | postnummer==75576 //a postal code (Vänge) which split up into three different codes during the study period.

assert date>=date("$start_date","DMY") & date<=date("$end_date","DMY")
Descriptive_Tests
putdocx paragraph
putdocx text ("After keeping only tests from $start_date to $end_date, number of tests is `=r(N)'"), linebreak(1)

drop if Provtagningsorsak=="Screening" | Provtagningsorsak=="Smittspårning"

Descriptive_Tests
putdocx text ("After removing screening, smittspårning, number of tests is `=r(N)'"),linebreak(1)

split Bestallare, parse(" ")
drop if (Provtagningsorsak=="Kliniska symtom-inneliggande vård" | Provtagningsorsak=="Screening" | Provtagningsorsak=="Smittspårning" ///
| Provtatgningsstation=="Akut barnsjukvård" | Provtatgningsstation=="Akut- och konsultpsykiatri" | Provtatgningsstation=="Akutsjukvård" ///
 | Provtatgningsstation=="Neurologi"  | Provtatgningsstation=="Aros Hälsocenter vårdcentral")  

assert agegroup!=.
drop if Bestallare1=="COVID-19,"

gen flag="keep" if (Provtagningsorsak=="Aktuell infektionsmisstanke" | Provtagningsorsak=="Kliniska symtom-egenvård i hemmet" ///
| Provtagningsorsak=="Symtom kvarstår" | Provtagningsorsak=="Åter till arbete" | Analys=="Egenprovtagning-Coronavirus COVID-19(SARS-CoV-2)" ///
| Analys=="Egenprovtagning-Luftvägsvirus (PCR)" | Analys=="Allmänheten-Coronavirus COVID-19 (SARS CoV 2) PCR" ///
| Analys=="ÖVRIGA PERSONAL-Coronavirus COVID-19 (SARS CoV 2) PCR" | Analys=="Luftvägsvirus (PCR) Litet block (inkl.SARS-CoV-2)" ///
| Analys=="Allmänheten-Luftvägsvirus (PCR) Litet block (inkl.SARS-CoV-2)")
*replace flag="keep" if Bestallare=="OKÄNT"
keep if flag=="keep"
drop flag

replace Provtatgningsstation="Skutskärs vårdcentral" if strpos(Provtatgningsstation,"Skutskär VC")
replace Provtatgningsstation="Heby vårdcentral" if strpos(Provtatgningsstation,"Heby VC")
replace Provtatgningsstation="Nyby vårdcentral" if strpos(Provtatgningsstation,"Nyby VC")
replace Provtatgningsstation="Tierps vårdcentral" if strpos(Provtatgningsstation,"Tierp VC")
replace Provtatgningsstation="Praktikertjänst Knivsta Läkargrupp" if strpos(Provtatgningsstation,"Praktikertjänst Knivsta")
replace Provtatgningsstation="Östhammars vårdcentral" if strpos(Provtatgningsstation,"Östhammar VC")
replace Provtatgningsstation="Kungsgärdets vårdcentral" if strpos(Provtatgningsstation,"Kungsgärdet VC")
replace Provtatgningsstation="Enköpings husläkarcentrum" if strpos(Provtatgningsstation,"Enköping husläkarcentrum VC")
replace Provtatgningsstation="Gottsunda vårdcentral" if strpos(Provtatgningsstation,"Gottsunda VC")

keep if inlist(Provtatgningsstation,"Kungsgärdets vårdcentral","Enköpings husläkarcentrum","Beredskapsjouren", ///
"Gottsunda vårdcentral","Praktikertjänst BålstaDoktorn","Beredskapsjour NVH","Tierps vårdcentral","Stenhagens vårdcentral") | ///
inlist(Provtatgningsstation,"Östhammars vårdcentral","Nyby vårdcentral","Praktikertjänst Bålsta","Heby vårdcentral","Praktikertjänst Knivsta Läkargrupp", ///
"Skutskärs vårdcentral","Aleris Närakut") | strpos(Provtatgningsstation,"Mobila Provtagningsenheten, Beredskap")

Descriptive_Tests
putdocx text ("After dropping non-patient-initiated tests, the number of tests is `=r(N)'"), linebreak(1)

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

drop AntalProvTot 

assert inrange(Antalejklar,0,1)
assert inrange(AntalProv,1,2)
assert inrange(Antalpositivaprov,0,2)
*****************************************************************************************************************************************************

***************************************Testing per class (hospital, primary care etc)
preserve
putdocx paragraph
collapse (sum) AntalProv,by(Provtatgningsstation)
gsort -AntalProv
gen Total=sum(AntalProv)
putdocx text ("Antal per provtagningsstation"),linebreak(1)
putdocx table klass_period=data(.),varnames
restore

keep postnummer Antal* date agegroup Gender Ålder
assert inrange(Ålder,5,105)
drop Ålder
collapse (sum) Antal*,by(Gender agegroup date postnummer)
//we want to have rows for every combination of postal code, date, agegroup, Gender, also the zero ones!
merge 1:1 postnummer date agegroup Gender using "MyData\date_postcode_matrix.dta",keep(match using) 
replace AntalProv=0 if _merge==2 //zero tests if only in using dataset
replace Antalpositivaprov=0 if _merge==2
replace Antalejklar=0 if _merge==2
drop _merge

merge n:1 postnummer using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Gender_Adult_pop.dta",nogenerate keep(match) assert(match using)
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
assert `=r(N)'==(596*2*5*351) //the number of rows should equal number of days * number of genders * number of agegroups * number of postal codes

fillin Gender agegroup date postnummer //asserting that every combination exists in the dataset
assert _fillin==0
drop _fillin
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData${Sensitivity}.dta",replace
//The file we've now created has one row per postal code, gender, agegroup and date
//relevant postal code level variables are added to the file in "1 Cleaning 20211130"

//add info about population to tables**********
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData${Sensitivity}.dta",clear
preserve
keep pop agegroup post
collapse (first) pop,by(post)
tostring postnummer,replace
gen area_75=substr(postnummer,1,2)
drop if postnummer=="75460" 
collapse (sum) pop,by(area_75)
list *
restore

preserve
destring postnummer,replace
keep pop agegroup post
collapse (first) pop,by(post)
merge 1:1 postnummer using "MyData\stadsdel.dta",nogenerate keep(match) assert(match using)
tostring postnummer,replace
drop if postnummer=="75460" 
gen Gottsunda=((strpos(stadsdel,"Gottsunda"))==1)
gen Sävja=inlist(postnummer,"75754","75755")
gen Cat="Sävja" if Sävja==1
replace Cat="Gottsunda" if Gottsunda==1
replace Cat="Övriga Uppsala" if Gottsunda==0 & Sävja==0
keep if substr(postnummer,1,2)=="75"
collapse (sum) pop,by(Cat)
list *
restore
******************
