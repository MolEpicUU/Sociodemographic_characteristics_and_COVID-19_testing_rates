//the population-average distances (see f.e. suppl table 1)
local county_distance=${Distance_metric} /*24.2*/ 
local city_distance=${Distance_metric} /*4.1*/

**************************This chunk is for generating the TRR:s*******************************************
foreach var of global outcome{
preserve

keep if postnummer=="74010" | postnummer=="75221"
replace pop=100000

lincom `county_distance'*`var',eform
gen county_distance=`=r(estimate)'
gen county_distance_lci=`=r(lb)'
gen county_distance_hci=`=r(ub)'
gen county_estimate=string(county_distance,"%9.2f")+" ("+string(county_distance_lci,"%9.2f")+"-"+string(county_distance_hci,"%9.2f")+")"

lincom `city_distance'*`var',eform
gen city_distance=`=r(estimate)'
gen city_distance_lci=`=r(lb)'
gen city_distance_hci=`=r(ub)'
gen city_estimate=string(city_distance,"%9.2f")+" ("+string(city_distance_lci,"%9.2f")+"-"+string(city_distance_hci,"%9.2f")+")"

gen IRR`var'=.
gen LCI`var'=.
gen HCI`var'=.
gen z`var'=.
count
//generates a TRR for each combination of date, gender, agegroup, area by looping through observations
forv i=1/`=r(N)'{
	noi di `i'
	local agegroup=agegroup[`i']
	local Gender=Gender[`i']
	local dspl1=date_spl1[`i']
	if "${model}"!="distance_hosp" & "${model}"!="distance_cases"{
		local dspl2=date_spl2[`i']
		local dspl3=date_spl3[`i']
		local dspl4=date_spl4[`i']
	}
	local a75=area_75[`i']

	if "${model}"!="distance_hosp" & "${model}"!="distance_cases"{ 
		lincom `var'+ /// main effect
		c.`var'#`agegroup'.agegroup+ ///
		c.`var'#`Gender'.Gender+ ///
		c.`var'#c.date_spl1*`dspl1'+ ///
		c.`var'#c.date_spl2*`dspl2'+ ///
		c.`var'#c.date_spl3*`dspl3'+ ///
		c.`var'#c.date_spl4*`dspl4'+ ///
		c.`var'#`a75'.area_75+ /// two-way interactions
		c.`var'#`a75'.area_75#`Gender'.Gender+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup+ ///
		c.`var'#`agegroup'.agegroup#`Gender'.Gender+ /// 
		c.`var'#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`agegroup'.agegroup#c.date_spl2*`dspl2'+ ///
		c.`var'#`agegroup'.agegroup#c.date_spl3*`dspl3'+ ///
		c.`var'#`agegroup'.agegroup#c.date_spl4*`dspl4'+ ///
		c.`var'#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
		c.`var'#`Gender'.Gender#c.date_spl2*`dspl2'+ ///
		c.`var'#`Gender'.Gender#c.date_spl3*`dspl3'+ ///
		c.`var'#`Gender'.Gender#c.date_spl4*`dspl4'+ ///
		c.`var'#`a75'.area_75#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#c.date_spl2*`dspl2'+ ///
		c.`var'#`a75'.area_75#c.date_spl3*`dspl3'+  ///
		c.`var'#`a75'.area_75#c.date_spl4*`dspl4'+ /// three-way interactions
		c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl2*`dspl2'+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl3*`dspl3'+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl4*`dspl4'+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl2*`dspl2'+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl3*`dspl3'+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl4*`dspl4'+ ///	
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl2*`dspl2'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl3*`dspl3'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl4*`dspl4'+ /// four-way interactions
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1*`dspl1'+  ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl2*`dspl2'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl3*`dspl3'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl4*`dspl4',eform /* five-way interactions*/
	}

	//This is the TRR using 10 kilometers instead of 1 (for easier interpretation)
	if ("$model"=="distance_hosp" | "$model"=="distance_cases"){
			if `a75'==1 local dist_to_use=`city_distance' 
			if `a75'==0 local dist_to_use=`county_distance' 
			lincom `dist_to_use'*`var'+ /// main effect
			`dist_to_use'*`var'#`agegroup'.agegroup+ ///
			`dist_to_use'*`var'#`Gender'.Gender+ ///
			`dist_to_use'*`var'#c.date_spl1*`dspl1'+ ///
			`dist_to_use'*`var'#`a75'.area_75+ /// two-way interactions
			`dist_to_use'*`var'#`a75'.area_75#`Gender'.Gender+ ///
			`dist_to_use'*`var'#`a75'.area_75#`agegroup'.agegroup+ ///
			`dist_to_use'*`var'#`agegroup'.agegroup#`Gender'.Gender+ /// 
			`dist_to_use'*`var'#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
			`dist_to_use'*`var'#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
			`dist_to_use'*`var'#`a75'.area_75#c.date_spl1*`dspl1'+ ///three-way interactions
			`dist_to_use'*`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup+ ///
			`dist_to_use'*`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
			`dist_to_use'*`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
			`dist_to_use'*`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///four-way interactions
			`dist_to_use'*`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1*`dspl1',eform /* five-way interactions*/			
	}
	
	replace IRR`var'=`=r(estimate)'  in `i'
	replace LCI`var'=`=r(lb)' in `i' 
	replace HCI`var'=`=r(ub)' in `i'
	replace z`var'=`=r(z)' in `i'
}

if "${outcome}"=="Distance" local ylbel "0.9 0.95 1 1.05"
if "${outcome}"=="CNI" local ylbel "0.5 0.75 1 1.5 2"

export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig3_${model}.xlsx",firstrow(variables) replace

putdocx paragraph
putdocx text ("`var'")

local titles `""Uppsala county, women, ages 5-14" "Uppsala county, men, ages 5-14" "Uppsala county, women, ages 15-29" "Uppsala county, men, ages 15-29" "Uppsala county, women, ages 30-49" "Uppsala county, men, ages 30-49" "Uppsala county, women, ages 50-69" "Uppsala county, men, ages 50-69" "Uppsala county, women, ages 70+" "Uppsala county, men, ages 70+""'
format date %tdDDMonYYYY
forv i=1/5{
	forv j=1/2{
	gettoken tok titles:titles
	twoway (rarea LCI`var' HCI`var' date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort color(gs10)) /// 
	(line IRR`var' date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort lcolor(black)), saving("Graph`i'`j'",replace) ///
	graphregion(color(white)) legend(off) ytitle("Incidence rate ratio")  title("`tok'") xlabel(,angle(90)) xtitle("Date") yscale(log) ylabel(`ylbel',angle(0)) yline(1,lcolor(red))
	}
}
graph combine "Graph11" "Graph12" "Graph21" "Graph22" "Graph31" "Graph32" "Graph41" "Graph42" "Graph51" "Graph52",xcommon ycommon graphregion(color(white)) iscale(*0.7)
putdocx paragraph
putdocx text ("Knot placement: 13aug2020, 12oct2020, 22feb2021, 13dec2021, 15jan2022")

graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph2_`var'.png",width(2000) replace
putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph2_`var'.png"

local titles `""Uppsala city, women, ages 5-14" "Uppsala city, men, ages 5-14" "Uppsala city, women, ages 15-29" "Uppsala city, men, ages 15-29" "Uppsala city, women, ages 30-49" "Uppsala city, men, ages 30-49" "Uppsala city, women, ages 50-69" "Uppsala city, men, ages 50-69" "Uppsala city, women, ages 70+" "Uppsala city, men, ages 70+""'
forv i=1/5{
	forv j=1/2{
	gettoken tok titles:titles
	putdocx text ("`var'")
	twoway (rarea LCI`var' HCI`var' date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort color(gs10)) /// 
	(line IRR`var' date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort lcolor(black)), saving("Graph`i'`j'",replace) ///
	graphregion(color(white)) legend(off) ytitle("Incidence rate ratio")  title("`tok'") xlabel(,angle(90)) xtitle("Date") yscale(log) ylabel(`ylbel',angle(0)) yline(1,lcolor(red))
	}
}
graph combine "Graph11" "Graph12" "Graph21" "Graph22" "Graph31" "Graph32" "Graph41" "Graph42" "Graph51" "Graph52",xcommon ycommon graphregion(color(white)) iscale(*0.7)
putdocx paragraph
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph3_`var'.png",width(2000) replace
putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph3_`var'.png"

keep LCI* HCI* IRR* date Gender agegroup area_75
merge n:1 date using "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesDatasets.dta",nogenerate
if "$model"=="distance_hosp" | "$model"=="distance_cases" drop if date>date("12oct2020","DMY")
save "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable.dta",replace //this is for creating the moving average plots
restore
}
******************************************************************************
