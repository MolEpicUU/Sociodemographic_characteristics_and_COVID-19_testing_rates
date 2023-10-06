//This file collects information about number (and cumulative number) of vaccinated per combination of postal code, date, gender, agegroup
//One dataset for each of the 5 first vaccination does is generated
//The code is run for all individuals or 15+ or 20+ age only. This is decided by the global "vaccine" variable set in "0 Run.do"

cd "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\SCB\leverans20210621"
import excel "UU_Postnummer202103.xlsx",firstrow clear cellrange(A8:BO10399)

//aggregates vaccine files for all weeks
clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData.dta",replace emptyok
	cd "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\PCR_files_complete\Vaccine"
	local files: dir . files "vaccin*xlsx"
	foreach var of local files{
		import excel "`var'",firstrow clear
		gen File="`var' `v2'"
		cap drop Typningsresultat
		cap drop Analys*
		append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData.dta"
		assert Utdelningsdatum>date("01jan2021","DMY")
		drop if Utdelningsdatum>date("09feb2022","DMY")
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData.dta",replace
}

//Creates one file for each dose order.
foreach i in 5 4 3 2 1{
	preserve
	keep if Dosordning=="`i'"
	bysort Personid: gen N=_N
	tab N
	drop N
	duplicates drop Personid,force
	isid Personid
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData`i'.dta",replace
	restore
}

//All files are potentially of interest for dose 1. (some individuals might be missing from "dosordning 1", 
//but we still want to count them in the "one dose" group if they have recieved the second one etc.
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData1.dta",clear
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData5.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData4.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData3.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData2.dta"
replace Dosordning="1"
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData1.dta",replace

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData2.dta",clear
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData5.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData4.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData3.dta"
replace Dosordning="2"
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData2.dta",replace

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData3.dta",clear
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData5.dta"
append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData4.dta"
replace Dosordning="3"
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData3.dta",replace

****some indivdiuals have inconsistent information between doses. This part of the code makes the information consistent.
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData.dta",clear
rename ZIPcode postnummer
replace postnummer=subinstr(postnummer," ","",.)
replace postnummer="74020" if postnummer=="75578" | postnummer=="75577" | postnummer=="75576"
bysort Personid (Utdelningsdatum): gen n=_n
assert n<=5
unique Personid 
putdocx paragraph
putdocx text ("`=r(unique)' individuals in total in the vaccination file"),linebreak(1)
destring postnummer Dosordning Personid,replace force
rename postnummer postnummer_tmp_tmp_tmp
gen postnummer=.
//Vi vill ha postnummer - i divergerande fall - som i första hand postnumret vid första dosen.
//Om detta saknas postnumret vid andra dosen...etc.
forv i=1/5{
	gen postnummer_tmp_tmp=postnummer_tmp_tmp_tmp if n==`i'
	egen postnummer_tmp=max(postnummer_tmp_tmp),by(Personid)
	replace postnummer=postnummer_tmp if postnummer==.
	if (`i'==5){
		unique Personid if postnummer!=postnummer_tmp_tmp_tmp
		putdocx text ("`=r(unique)' individuals with diverging postal codes between doses"),linebreak(1)
		putdocx text ("I define them as belonging to the first postal code"),linebreak(1)
	}
	drop postnummer_tmp_tmp postnummer_tmp
}

//we want age to be congruent between the doses, otherwise we define it as missing.
egen Ålder=min(OrdinationskontaktÅlder),by(Personid)
egen Test=max(OrdinationskontaktÅlder),by(Personid)
gen Diff=Ålder-Test //ny 2022-06-02
assert Diff<=0
unique Personid if Diff<-2
putdocx text ("`=r(unique)' individuals which are two years older or more during the last dose than the first. I define them as missing on age"),linebreak(1)
replace Ålder=. if Diff<-2
drop Diff Test
if "${vaccine}"=="20+" replace Ålder=. if Ålder<20
if "${vaccine}"=="15+" replace Ålder=. if Ålder<15 //15 used in the paper 
gen agegroup=1 if inrange(Ålder,5,14)
replace agegroup=2 if inrange(Ålder,15,29)
replace agegroup=3 if inrange(Ålder,30,49)
replace agegroup=4 if inrange(Ålder,50,69)
replace agegroup=5 if inrange(Ålder,70,106)

//..same for gender
gen Gender_tmp=1 if Kön=="Kvinna"
replace Gender_tmp=2 if Kön=="Man"
egen Gender=min(Gender),by(Personid)
egen Test=max(Gender),by(Personid)
assert Gender==Test //i.e. no problems for gender
putdocx text ("Gender is congruent for all individuals"),linebreak(1)
assert Gender==1 | Gender==2 | Gender==.
drop Test
keep Personid postnummer agegroup Gender
drop if Personid==.
duplicates drop
bysort Personid postnummer: gen N=_N
assert N==1
drop N
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData_postnummer.dta",replace
***************************************************

forv i=1/3{
	use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData`i'.dta",clear
	unique Personid
	putdocx text ("`=r(unique)' individuals with at least `i' dose"),linebreak(1)

	***This part makes sure that only individuals with known age and gender will be counted, and that they will be assigned to their
	***earliest known postal code (as defined in "VaccineData_postnummer). 
	keep OrdinationskontaktÅlder Utdelningsdatum Dosordning ZIPcode Kön Personid
	destring Dosordning Personid,replace force
	drop if Personid==. | Utdelningsdatum==.
	drop ZIPcode
	merge n:1 Personid using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData_postnummer.dta",keep(match) nogenerate assert(using match)
	drop if postnummer==. | Gender==. | agegroup==.
	duplicates drop
	isid Personid Utdelningsdatum
	bysort Personid (Utdelningsdatum): gen n=_n
	keep if n==1 //makes sure that only the first instance of the individual is kept
	unique Personid
	putdocx text ("...of which `=r(unique)' individuals remains after dropping individuals with missing age, gender or postal code"),linebreak(1)
	*************************************** 
	
	drop Personid n
	rename Utdelningsdatum date
	gen Antal=1
	collapse (sum) Antal,by(postnummer Gender agegroup date)
	assert Antal!=.
	merge 1:1 postnummer Gender agegroup date using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\date_postcode_matrix.dta",keep(using match) nogenerate
	replace Antal=0 if Antal==.
	tostring postnummer,replace
	isid postnummer Gender agegroup date
	bysort postnummer Gender agegroup (date): gen AntalVacc_Cumul`i'=sum(Antal)
	rename Antal Antal_Vacc`i'
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData`i'.dta",replace
}
