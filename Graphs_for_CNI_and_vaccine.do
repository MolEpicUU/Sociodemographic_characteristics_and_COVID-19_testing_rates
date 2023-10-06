//This chunk produces moving average and moving sum variables for tests, hospitalizations and positive tests
//Moving averages are separate for city and county. Moving sums are joint (that's the reason for the 0/2 instead of 0/1 - to include both city and county)
//when we replace area_75=2 it means that sums and moving averages will be calculated for the entire data instead.
forv i=0/2{
	preserve
	bysort postnummer date: gen n=_n
	replace Antalpatienter=. if n!=1 //because "Antalpatienter" is defined on postalcode+date-level, so we want no "double-counting" by age and gender here.
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
		save "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesDatasets.dta",replace //This file is used in "3 Analys.do"
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
	replace Antalpatienter=. if n!=1 //because "Antalpatienter" is defined on postalcode+date-level, so we want no "double-counting" by age and gender here.
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
