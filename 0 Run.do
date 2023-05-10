/*This file runs the entire code at once and saves the output in a Word document
Four separate documents are produced for four different models. One for positive case adjustment, one for hospitalizations,
one without adjustment ("crude") and one adjusting for distance.
*/

clear mata
clear matrix
local main_counter=0

global vaccine "All" /*"All" "20+ 15+"*/ //specify 20+ for calculating vaccination coverage in age 20+, 
//15+ for vaccination coverage in age 15+

foreach model in cases /*hospitalizations crude distance_cases*/{
	local main_counter=`main_counter'+1
	global model "`model'"
	global outcome "CNI"
	cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData"
	cap putdocx save "Inequalities_in_testing${model}${outcome}_`c(current_date)'.docx",replace
	putdocx begin
	//The first four codes are essentially preprocessing of data
	if `main_counter'==1{
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Preprocessing.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Hospitalizations.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\CNI.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Agegroup Populations.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\2 Vaccine.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\1 Cleaning 20211130.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\DescriptiveStatistics_alt.do"
	}
	do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\3 Analys.do"

	cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData"
	putdocx save "Inequalities_in_testing${model}${outcome}_`c(current_date)'.docx", replace
}
