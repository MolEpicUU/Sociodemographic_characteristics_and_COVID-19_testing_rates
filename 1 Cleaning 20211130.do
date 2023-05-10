//In this code we merge the main file created in "Preprocessing.do" with information about CNI, hospitalizations, age groups etc.
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear

cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"

tostring postnummer,replace
gen area=substr(postnummer,1,2)
gen area_75=(area=="75")
cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\"
destring postnummer,replace
merge n:1 postnummer using "MyData\stadsdel.dta",nogenerate keep(match) assert(match using)
tostring postnummer,replace

gen Gottsunda=((strpos(stadsdel,"Gottsunda"))==1)
gen Sävja=inlist(postnummer,"75754","75755")
gen Cat="Sävja" if Sävja==1
replace Cat="Gottsunda" if Gottsunda==1
replace Cat="Övriga Uppsala" if Gottsunda==0 & Sävja==0

*****************************************************************************************
//Here we select period for "2_Analysis"
merge 1:1 postnummer date Gender agegroup using "MyData\Hospitalization_Table.dta",nogenerate keep(match) 
drop Antalnegativaprov Antalgränsvärde //Antalgränsvärde är 0 för alla (eller missing, för de rader som är tillagda via merge)
gen positivity=Antalpositivaprov/(AntalProv-Antalejklar)*100

merge n:1 postnummer using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\AgegroupPopulations.dta",nogenerate assert(match using) keep(match)
//code to generate this...?
destring postnummer,replace
merge n:1 postnummer using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Alder.dta",nogenerate keep(master match)
tostring postnummer,replace

egen Distance=rowmin(distance_driving_enkoping distance_driving_tierp distance_driving_osthammar distance_driving_uppsala)

forv i=1/3{
	merge n:1 postnummer Gender agegroup date using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\VaccineData`i'.dta",keep(master match) nogenerate //merge with info about postal code vaccine rates
}
assert AntalVacc_Cumul1>=AntalVacc_Cumul2
assert AntalVacc_Cumul2>=AntalVacc_Cumul3

assert area_75==0 | area_75==1

drop if postnummer=="75460" //no CNI
merge n:1 postnummer using "MyData/CNI.dta", keep(match) assert(match using) nogenerate  //merge with Care Need Index info

drop distance_driving* Antalejklar area Antal_Vacc? AntalVacc_Cumul1  AntalVacc_Cumul3 stadsdel
save "MyData\MainData.dta",replace

count
assert `=r(N)'==(596*2*5*350) //the number of rows should equal number of days * number of genders * number of agegroups * number of postal codes
unique postnummer
assert `=r(unique)'==350
