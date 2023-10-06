//This codes preprocesses and converts data files into Stata format. The main file here is "date_postcode_matrix",
//containing each possible combination of date, postal code, gender and age group during the study period.
//This will be merged with the main (PCR test) file to ensure 1)that every combination, even with zero tests, are respresented in the analysis.
//2)That we only analyze the postal codes relevant for Uppsala (populated one mainly situated in the county/city).
cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
putdocx paragraph

//A file containing the category of each testing station (to be used for the descriptive analysis of tests)
import excel "OriginalData\Provtagningsstationer_categorized_230822.xlsx",firstrow clear
drop Prov E F G
rename D Class
replace Class="Testing station used in paper" if KeepProvtagningsenheten=="Yes"
duplicates drop
save "Provtagningsstationer_categorized_230822.dta",replace
*******************************************************************

******************************POSTAL CODES********************************************************
//Population per sex and age group for five-digit-codes. This is used for only keeping populated codes in the analysis
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

tostring postnummer,replace
//postal codes mostly overlapping with other counties
drop if inlist(postnummer,"73391","73392","73398","19592","19593")
drop if inlist(postnummer,"64593","72596","76295","76296","76297")
drop if postnummer=="75460" //no CNI

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

********************************SAVE A FILE FOR CITY PARTS*****************************************************
//this is for the diff-in-diff analysis between Gottsunda and Sävja
import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Toves cleaning scripts and temp files\infiles\stadsdel_update.xlsx",firstrow clear //file matching postal code to suburb/city area in Uppland.
save "MyData\stadsdel.dta",replace
*************************************************************************************'
