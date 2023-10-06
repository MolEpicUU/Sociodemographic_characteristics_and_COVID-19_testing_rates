/*This file runs the entire code at once and saves the output in a Word document
Four separate documents are produced for four different models. One for positive case adjustment, one for hospitalizations,
one without adjustment ("crude") and one adjusting for distance.
*/

***********************GLOBAL SETTINGS (can be modified by user)****************************
if "$model"=="distance" global All "" //entire preprocessing code, even slow-running parts if "all"
if "$model"!="distance" global All "" //entire preprocessing code, even slow-running parts if "all"
global start_date="24jun2020"
global end_date="09feb2022"
***************************************************************

clear mata
clear matrix
local main_counter=0

global vaccine "15+" /*"All" "20+ 15+"*/ //specify 20+ for calculating vaccination coverage in age 20+, 
//15+ for vaccination coverage in age 15+
global CaseDD "no_case" /*"case" "no_case"*/ //adjustment for positive cases (or not) in the diff-in-diff analysis
global Distance_metric "10" /*1 10*/ //how to express TRR in the distance_cases analysis (in km)

foreach model in distance_cases /*hospitalizations crude distance_cases cases*/{
	local main_counter=`main_counter'+1
	global model "`model'"
	cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData"
	cap putdocx save "Inequalities_in_testing${model}${outcome}${CaseDD}_`c(current_date)'_${Distance_metric}km.docx",replace
	putdocx begin
	//The first codes are essentially preprocessing of data
	if `main_counter'==1{
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\CNI.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Preprocessing.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\PCR_tests.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Hospitalizations.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Agegroup Populations.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\2 Vaccine.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\1 Cleaning 20211130.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\DescriptiveStatistics_alt.do"
		do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\ReviewerComments_stratified_analysis.do"
	}
	do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\3 Analys.do"
	do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Difference_in_difference_analysis.do"
	do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\County_vs_City_patterns.do"
	
	cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData"
	putdocx save "Inequalities_in_testing${model}${outcome}${CaseDD}_`c(current_date)'_${Distance_metric}km.docx", replace
}
do "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Restructuring_files_for_Yorgo.do"


/*
The following files are called inside PCR_tests.do:
*include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_1.do" //just some descriptives irrelevant for main code
*include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_2.do" //just some descriptives irrelevant for main code
*include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Descriptive_categorization_of_tests_3.do" //just some descriptives irrelevant for main code
*/

/*
The following files are called inside 3 Analysis.do:
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\p_values_for_TRR_plots.do"
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\marginal_effects_plots.do"
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\TRR_plots.do"
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Moving average plots and TRR tables.do"
*/

*The following file is called inside DescriptiveStatistics_alt.do:
*include Graphs_for_CNI_and_vaccine.do"
