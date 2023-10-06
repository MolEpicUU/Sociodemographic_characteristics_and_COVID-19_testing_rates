*Here we generate table1, plots etc.
	
*************Importing main file***********************
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData/MainData.dta",clear

//histogram of CNI distribution
if "$model"=="cases"{
	preserve
	keep postnummer CNI area_75
	duplicates drop
	label define Lab 0 "Uppsala County" 1 "Uppsala City"
	label values area_75 Lab
	*subtitle("") 
	hist CNI,freq graphregion(color(white)) by(area_75,graphregion(color(white)) note("")) xtitle("CNI") subtitle(,fcolor(white))
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_hist.png",width(2000) replace
	putdocx paragraph
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_hist.png"
	restore
}

encode postnummer,gen(postnummer_num)

//generate splines for date variable (centered at 0)
sum date
local min=`=r(min)'
gen date_0=date-`min'
local knot1=date("13aug2020","DMY")-`min'
local knot2=date("12oct2020","DMY")-`min'
local knot3=date("22feb2021","DMY")-`min'
local knot4=date("13dec2021","DMY")-`min'
local knot5=date("15jan2022","DMY")-`min'
mkspline date_spl=date_0,knots(`knot1' `knot2' `knot3' `knot4' `knot5') cubic

assert inrange(agegroup,1,5)

//change the "pop" variable to reflect the specific agegroup and sex, not the entire postal code pop.
gen population=pop //because we need a variable for the entire postcode population as well
replace pop=pop_5_14_female if agegroup==1 & Gender==1
replace pop=pop_15_29_female if agegroup==2 & Gender==1
replace pop=pop_30_49_female if agegroup==3 & Gender==1
replace pop=pop_50_69_female if agegroup==4 & Gender==1
replace pop=pop_70_105_female if agegroup==5 & Gender==1

replace pop=pop_5_14_male if agegroup==1 & Gender==2
replace pop=pop_15_29_male if agegroup==2 & Gender==2
replace pop=pop_30_49_male if agegroup==3 & Gender==2
replace pop=pop_50_69_male if agegroup==4 & Gender==2
replace pop=pop_70_105_male if agegroup==5 & Gender==2

gen Vaccin_rate2=AntalVacc_Cumul2/pop*100

gen AntalpatienterPer100000=Antalpatienter/population*100000 //"population" because it's patients for the entire postal code
gen AntalPositivaPer100000=Antalpositivaprov/pop*100000 //"pop" because it's tests specific for agegroup and sex

set matsize 1000
mkspline PosSpline=AntalPositivaPer100000,knots(-10 500 2000 40000) cubic
mkspline PatSpline=AntalpatienterPer100000,knots(-10 35 75 200) cubic

format date %tdDDMonCCYY

egen CNI_cat=cut(CNI),group(4) //this works since all postal codes have the same number of rows by default.
include "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\Codes\Graphs_for_CNI_and_vaccine.do"
gen weekday=dow(date)

save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData/MainData.dta",replace
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData/MainData.dta",clear
****************************TABLE 1***************************************
//This part of the code requires collapsing the data to postal code level. Therefore no save of the main file here.
gen Vacc_09feb_tmp=AntalVacc_Cumul2 if date==22685
egen Vacc_09feb=sum(Vacc_09feb_tmp),by(postnummer)
if "$vaccine"=="All" replace Vacc_09feb=Vacc_09feb/population*100
if "$vaccine"=="20+" replace Vacc_09feb=Vacc_09feb/(pop_20_105)*100
if "$vaccine"=="15+" replace Vacc_09feb=Vacc_09feb/(pop_15_105)*100

egen AvPat=mean(Antalpatienter),by(postnummer date) //"mean" because the number is a duplicate for all combinations of age group and gender. Therefore "sum" would be wrong.
gen AvPatPer100000_date=AvPat/population*100000
egen AntalPos=sum(Antalpositivaprov),by(postnummer date)
gen AntalPosPer100000_date=AntalPos/population*100000
egen AvPatPer100000=mean(AvPatPer100000_date),by(postnummer)
egen AntalPosPer100000=mean(AntalPosPer100000_date),by(postnummer)

drop pop Antalpatienter  positivity AntalVacc_Cumul2
keep pop* postnummer andel_kvinnor area_75-Unemployed Vacc_09feb AvPatPer100000 AntalPosPer100000 Distance Cat

//creating percentages
replace andel_kvinnor=andel_kvinnor*100
replace NonEU=NonEU/population*100
replace Below5=Below5/population*100
replace Unemployed=Unemployed/pop_15_64*100
replace PersonsAbove=PersonsAbove/population*100
replace LowEducation=LowEducation/pop_25_64*100
replace Above65=Above65/pop_65_plus*100
replace SingleParent=SingleParent/population*100

duplicates drop
isid postnummer

label variable Below5 "Age below 5 years (%)"
label variable NonEU "Born in East- or South Europe (outside the EU), Africa, Asia or South America (%)"
label variable Above65 "Age over 65 (single household) (%)"
label variable SingleParent "Single parent with child below 18 years (%)"
label variable PersonsAbove "Persons one year old or more moved into area (%)"
label variable Unemployed "Unemployed or in labor market measures (16-64 years) (%)"
label variable LowEducation "Low education (25-64 years) (%)"
label variable AvPatPer100000 "Average number of daily hospitalizations per 100,000"
label variable Vacc_09feb "% vaccinated twice as of 09th Feb 2022"
label variable Distance "Distance to closest testing station (km)"
label variable AntalPosPer100000 "Average number of positive tests per 100,000"
label variable andel_kvinnor "Women (%)"
label variable CNI "Care Need Index"

//collapsing male and female populations
foreach var in  pop_5_14 pop_15_29 pop_30_49 pop_50_69 pop_70_105{
	egen `var'=rowtotal(`var'*)
}

foreach var in pop_5_14 pop_15_29 pop_30_49 pop_50_69 pop_70_105{
	replace `var'=`var'/population*100
}

format andel_kvinnor AvPatPer100000 AntalPosPer100000 Above65 LowEducation PersonsAbove Unemployed Below5 NonEU CNI Vacc_09feb pop* SingleParent %9.1f

//calculates correlations weighted on population size
corr CNI andel_kvinnor  Below5  NonEU  Above65  SingleParent  PersonsAbove  ///
LowEducation  Unemployed Distance if area_75==0 [weight=population]
matrix CorrCounty=r(C)
corr CNI andel_kvinnor  Below5  NonEU  Above65  SingleParent  PersonsAbove  ///
LowEducation  Unemployed  Distance if area_75==1 [weight=population]
matrix CorrCity=r(C)

//Weighted table1
if "$model"=="cases"{

	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_tot.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_City.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' if area_75==1 [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_County.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' if area_75==0 [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Gottsunda.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' if area_75==1 & Gottsunda==1 [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Sävja.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' if area_75==1 & Sävja==1 [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
	cap postclose myfile
	postfile myfile str30 Variable double med p25 p75 using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Uppsala_Övr.dta",replace
	foreach var in CNI population andel_kvinnor Below5 NonEU Above65 SingleParent PersonsAbove LowEducation Unemployed Distance Vacc_09feb{
		sum `var' if area_75==1 & Sävja==0 & Gottsunda==0 [fweight=population],det
		post myfile ("`: var label `var''") (`=r(p50)') (`=r(p25)') (`=r(p75)')
	}
	postclose myfile
	
local Loc=0
foreach var in Table1_tot Table1_City Table1_County{
	use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\\`var'.dta",clear
	gen Estimate`Loc'=string(med,"%9.1f")+" ("+string(p25,"%9.1f")+", "+string(p75,"%9.1f")+")"
	drop med p25 p75
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\\`var'_clean.dta",replace
	local Loc=`Loc'+1
}
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_tot_clean.dta",clear
gen n=_n
merge 1:1 Variable using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_City_clean.dta",assert(match) nogenerate
merge 1:1 Variable using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_County_clean.dta",assert(match) nogenerate
sort n
drop n
rename (Estimate0 Estimate1 Estimate2) (Overall City County)
order Overall,last
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1.xlsx",replace firstrow(variables)
putdocx table tbl=data(.)
	
	use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Gottsunda.dta",clear
	gen Gottsunda=string(med,"%9.1f")+" ("+string(p25,"%9.1f")+", "+string(p75,"%9.1f")+")"
	drop med p25 p75
	gen n=_n
	merge 1:1 Variable using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Sävja.dta",nogenerate
	gen Sävja=string(med,"%9.1f")+" ("+string(p25,"%9.1f")+", "+string(p75,"%9.1f")+")"
	drop med p25 p75
	merge 1:1 Variable using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Table1_Uppsala_Övr.dta",nogenerate
	gen Uppsala=string(med,"%9.1f")+" ("+string(p25,"%9.1f")+", "+string(p75,"%9.1f")+")"
	drop med p25 p75
	sort n
	drop n
	putdocx paragraph
	putdocx text ("Gottsunda, Sävja, deskriptiv tabell")
	putdocx table tbl2=data(.)	
	
	//stores the correlation matrices in excel file for plotting in R_plots.R
	clear
	svmat2 CorrCounty,rnames(Var) names(eqcol)
	order Var,first
	export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Corr_County.xlsx",replace
	clear
	svmat2 CorrCity,rnames(Var) names(eqcol)
	order Var,first
	export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Corr_City.xlsx",replace
}

*********************************************************************************************************************
//this part - putting the correlation plot inside the dynamic document - requires first running R_plots.R to work
putdocx paragraph
putdocx text ("Correlation graph")
*putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Corrplot.png"

