//this code generates a table of hospitalizations which can be merged to the main file.
//The resulting dataset has one row for each combination of  postal code, gender, age group and date.
//The hospitalization variable is on the level of postal code and date.
**********************************HOSPITALIZATIONS****************************************************
if "${All}"=="All"{ 
	//Matching five-digit codes to hospitalizations
	cd "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\Hospital_UU\CRUSH 06"
	import excel "sjukhus inskrivna.xlsx", first clear //740 20 jättestor skillnad!!!!!!

	cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\"

	rename ContactStart date
	drop if ZipCode=="" //removing the "total" columns
	assert Antalpatienter<5 
	rename ZipCode postnummer

	replace postnummer=subinstr(postnummer," ","",.)
	replace postnummer="74020" if postnummer=="75578" | postnummer=="75577" | postnummer=="75576"
	destring postnummer,replace

	keep postnummer Antalpatienter date

	//several rows per postal code/date since there are several hospital departments.
	collapse (sum)  Antalpatienter, by(postnummer date)

	//postcode matrix is a dataset containing all relevant combinations of gender/agegroup/postcode/dates.
	//note that we don't have gender or age distribution of hospitalizations, therefore 
	merge 1:n date postnummer using "MyData\date_postcode_matrix.dta",nogenerate keep(match using)

	replace Antalpatienter=0 if Antalpatienter==. //those that do not match
	assert date!=.
	tostring postnummer,replace
	
	count
	assert `=r(N)'==(596*2*5*351) //the number of rows should equal number of days * number of genders * number of agegroups * number of postal codes
	fillin Gender agegroup date postnummer //asserting that every combination exists in the dataset
	assert _fillin==0
	drop _fillin
	save "MyData\Hospitalization_Table.dta",replace
}
