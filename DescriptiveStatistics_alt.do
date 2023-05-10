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
rename pop2 pop
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
*assert Vaccin_rate2<=100

gen AntalpatienterPer100000=Antalpatienter/population*100000 //"population" because it's patients for the entire postal code
gen AntalPositivaPer100000=Antalpositivaprov/pop*100000 //"pop" because it's tests specific for agegroup and sex

set matsize 1000
mkspline PosSpline=AntalPositivaPer100000,knots(-10 500 2000 40000) cubic
mkspline PatSpline=AntalpatienterPer100000,knots(-10 35 75 200) cubic

format date %tdDDMonCCYY

egen CNI_cat=cut(CNI),group(4) //this works since all postal codes have the same number of rows by default.

	//This chunk produces moving average and moving sum variables for tests, hospitalizations and positive tests
	//Moving averages are separate for city and county. Moving sums are joint (that's the reason for the 0/2 instead of 0/1 - to include both city and county)
	forv i=0/2{
		preserve
		bysort postnummer date: gen n=_n
		replace Antalpatienter=. if n!=1
		if `i'==2{
			replace area_75=2
		}
		if `i'==0 local title "Uppsala County"
		if `i'==1 local title "Uppsala City"
			egen hosp_tot=sum(Antalpatienter),by(date area_75)
			egen pos_tot=sum(Antalpositivaprov),by(date area_75)
			egen tests_tot=sum(AntalProv),by(date area_75)
			egen pop_tot=sum(pop),by(date area_75)
		replace tests_tot=tests_tot/pop_tot*100000
		replace pos_tot=pos_tot/pop_tot*100000
		replace hosp_tot=hosp_tot/pop_tot*100000
		keep if area_75==`i'
		keep date pos_tot tests_tot hosp_tot
		duplicates drop
		tsset date 
		egen pos_tot_ma7 = filter(pos_tot), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
		egen tests_tot_ma7 = filter(tests_tot), coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
		egen hosp_tot_ma7 = filter(hosp_tot),coef(1 1 1 1 1 1 1) lags(-3/3) normalise 
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Tests_hospitalizations_graph`i'_for_R.dta",replace
		twoway (line hosp_tot_ma7 date,sort),legend(off) graphregion(color(white)) ytitle("Hospitalizations per 100,000") ///
		xtitle("Date") saving("GrH`i'",replace) title("`title'") xlabel(22111 `""Jul" "2020""' ///
		22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""')
		twoway (line tests_tot_ma7 date,sort) (line pos_tot_ma7 date,sort), legend(order(1 "Total" 2 "Positive")) ///
		graphregion(color(white)) xtitle("Date") ytitle("Tests per 100,000") saving("Gr`i'",replace) title("`title'") ///
		xlabel(22111 `""Jul" "2020""' ///
		22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""') name("Gr`i'",replace)
		if (`i'==2){ 
			drop *ma7
			egen pos_tot_ma14_`i' = filter(pos_tot), coef(0.5 1 1 1 1 1 1 1 1 1 1 1 1 1 0.5) lags(-7/7) //sums, so "normalize" is not needed here. 7 days before and 7 days after, therefore 0.5
			egen pos_tot_ma7_`i' = filter(pos_tot), coef(1 1 1 1 1 1 1) lags(-3/3) 
			egen tests_tot_ma7_`i' = filter(tests_tot), coef(1 1 1 1 1 1 1) lags(-3/3)
			egen hosp_tot_ma7_`i' = filter(hosp_tot),coef(1 1 1 1 1 1 1) lags(-3/3)
			keep date pos_tot_ma7_`i' pos_tot_ma14_`i' tests_tot_ma7_`i' pos_tot_ma7_`i' hosp_tot_ma7_`i'
			save "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesDatasets.dta",replace
		}
		restore
	}
	putdocx paragraph
	putdocx text ("Graphs of total and positive tests per 100,000")
	graph combine "Gr0" "Gr1", ycommon iscale(*0.6) graphregion(color(white))
	
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\area_tests.png",replace width(2000)
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\area_tests.png"
	
	putdocx text ("Graphs of hospitalizations per 100,000")
	graph combine "GrH0" "GrH1", ycommon iscale(*0.6) graphregion(color(white)) //varför inte större skillnader?
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\areaH_tests.png",replace width(2000)
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\areaH_tests.png"
	
	//This chunk produces moving average variables & graphs for quartiles of CNI (hospitalizations and tests).
	forv i=0/3{
		preserve
		bysort postnummer date: gen n=_n
		replace Antalpatienter=. if n!=1
		egen hosp_tot=sum(Antalpatienter),by(date CNI_cat)
		egen pos_tot=sum(Antalpositivaprov),by(date CNI_cat)
		egen tests_tot=sum(AntalProv),by(date CNI_cat)
		egen pop_tot=sum(pop),by(date CNI_cat)
		replace tests_tot=tests_tot/pop_tot*100000
		replace pos_tot=pos_tot/pop_tot*100000
		replace hosp_tot=hosp_tot/pop_tot*100000
		keep date pos_tot tests_tot hosp_tot CNI_cat
		keep if CNI_cat==`i'
		duplicates drop
		tsset date
		local incr=`i'+1
		egen pos_tot_ma7 = filter(pos_tot), coef(1 1 1 1 1 1 1) lags(-3/3) normalise
		egen tests_tot_ma7 = filter(tests_tot), coef(1 1 1 1 1 1 1) lags(-3/3) normalise
		egen hosp_tot_ma7 = filter(hosp_tot),coef(1 1 1 1 1 1 1) lags(-3/3) normalise
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_cat_graph`i'_for_R.dta",replace
		twoway (line hosp_tot_ma7 date,sort),legend(order(1 "COVID-19 hospital admissions per 100,000")) graphregion(color(white)) ytitle("COVID-19 hospital admissions per 100,000") ///
		xtitle("Date") saving("Hosp`i'",replace) title("Quartile `incr'") xlabel(22111 `""Jul" "2020""' ///
		22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""')
		twoway (line tests_tot_ma7 date,sort) (line pos_tot_ma7 date,sort), legend(order(1 "Total" 2 "Positive")) ///
		graphregion(color(white)) xtitle("Date") ytitle("Tests per 100,000") saving("Graph`i'",replace) title("Quartile `incr'") ///
		xlabel(22111 `""Jul" "2020""' ///
		22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""')
		restore
	}
	
	putdocx paragraph
	putdocx text ("Graphs of total and positive tests per 100,000, by quartiles of CNI")
	graph combine "Graph0" "Graph1" "Graph2" "Graph3", ycommon iscale(*0.6) graphregion(color(white)) //varför inte större skillnader?
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_tests.png",replace width(2000)
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_tests.png"
	
	putdocx text ("Graphs of hospitalizations per 100,000, by quartiles of CNI")
	graph combine "Hosp0" "Hosp1" "Hosp2" "Hosp3", ycommon iscale(*0.6) graphregion(color(white)) //varför inte större skillnader?
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_hosp.png",replace width(2000)
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_hosp.png"

	//This chunk produces graphs for cumulative vaccine coverage by CNI
	local titles `""Uppsala County" "Uppsala City""'
	forv i=0/1{
	foreach vr of varlist CNI{
		gettoken tl titles:titles
		preserve
		keep if area_75==`i'
		cap drop CNI_cat
		egen `vr'_cat=cut(`vr'),group(4) //funkar iom att alla postkoder har samma antal rader by default	
		egen AntalVacc_Tot=sum(AntalVacc_Cumul2),by(date `vr'_cat)
		if "${vaccine}"=="All" egen pop_tot=sum(pop),by(date `vr'_cat)
		if "${vaccine}"=="20+"{ 
			keep if agegroup==3 & Gender==1
			egen pop_tot=sum(pop_20_105),by(date `vr'_cat)
		}
		if "${vaccine}"=="15+"{ 
			keep if agegroup==3 & Gender==1
			egen pop_tot=sum(pop_15_105),by(date `vr'_cat)
		}
		gen Vacc_Perc=AntalVacc_Tot/pop_tot
		keep date Vacc_Perc `vr'_cat
		duplicates drop
		export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\CNI_vacc_`i'",firstrow(variables) replace

		twoway (line Vacc_Perc date if `vr'_cat==0,sort lcolor(red)) (line Vacc_Perc date if `vr'_cat==1,sort lcolor(orange)) (line Vacc_Perc date if `vr'_cat==2,sort lcolor(black)) ///
		(line Vacc_Perc date if `vr'_cat==3,sort lcolor(blue)), /// 
		xtitle("Date") ytitle("% vaccinated") graphregion(color(white)) ylabel(0 "0" 0.20 "20" 0.40 "40" 0.6 "60" 0.8 "80" 1 "100",angle(0)) xlabel(22111 `""Jul" "2020""' ///
		22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""') legend(title("`vr'",size(*0.8)) order(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4") ring(0) size(*0.7) symxsize(*0.3) bmargin(20 20 5 15) position(11)) ///
		saving("`vr'`i'",replace) title("`tl'")
		restore
	}
	}
grc1leg "CNI0" "CNI1",ring(0) position(10) legendfrom("CNI1") graphregion(color(white)) iscale(*1.1)
putdocx paragraph
putdocx text ("Cumulative % of 2 times vaccinated by city/county")
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\\vacc_county_city.png",replace width(2000)
putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\vacc_county_city.png"
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

egen AvPat=mean(Antalpatienter),by(postnummer date)
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
putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Corrplot.png"

