//THIS GENERATES MODEL-BASED GRAPHS FOR EVENTS (per 100,000)
foreach var of global outcome{
preserve
	sum AntalpatienterPer100000
	replace AntalpatienterPer100000=`=r(mean)'

	//fixes covariates to certain values for marginal effects graphs***********
	replace pop=100000
	replace Vaccin_rate2=0

	forv spl=1/3{
		replace PosSpline`spl'=0
		replace PatSpline`spl'=0
	}
	replace weekday=3
		sum `var' if area_75==0,det
		local p100=`=r(p10)'
		local p900=`=r(p90)'
		sum `var' if area_75==1,det
		local p101=`=r(p10)'
		local p901=`=r(p90)'
		if "`var'"=="Distance"{
			sum CNI
			replace CNI=`=r(mean)'
		}
*********************************************************************

	*****generates predictions and their confidence intervals for county and city**********
	keep if postnummer=="74010" | postnummer=="75221" //we need one postal code from Uppsala City and one code from Uppsala County for generating the plots
	forv i=0/1{
		replace `var'=`p10`i''
		local perc_10`i': di %9.2f `p10`i''
		local perc_90`i': di %9.2f `p90`i''
		predict EventRate0`i',xb
		predict se0`i',stdp
		replace `var'=`p90`i''
		predict EventRate5`i',xb
		predict se5`i',stdp
		gen LCI_Ev0`i'=EventRate0`i'+invnormal(0.025)*se0`i'
		gen HCI_Ev0`i'=EventRate0`i'+invnormal(0.975)*se0`i'

		gen LCI_Ev5`i'=EventRate5`i'+invnormal(0.025)*se5`i'
		gen HCI_Ev5`i'=EventRate5`i'+invnormal(0.975)*se5`i'

		replace LCI_Ev0`i'=exp(LCI_Ev0`i')
		replace HCI_Ev0`i'=exp(HCI_Ev0`i')
		replace EventRate0`i'=exp(EventRate0`i')

		replace LCI_Ev5`i'=exp(LCI_Ev5`i')
		replace HCI_Ev5`i'=exp(HCI_Ev5`i')
		replace EventRate5`i'=exp(EventRate5`i')
	}

	//generates legends for plots (both county and city***********
	if "`var'"=="CNI"{
		local Leg10 "CNI=`perc_100'"
		local Leg20 "CNI=`perc_900'"
		local Leg11 "CNI=`perc_101'"
		local Leg21 "CNI=`perc_901'"
	}
	if "`var'"=="Distance"{
		local Leg10 "Dist.=`perc_100'"
		local Leg20 "Dist.=`perc_900'"
		local Leg11 "Dist.=`perc_101'"
		local Leg21 "Dist.=`perc_901'"
	}

	forv i=0/1{
		local Leg1`i': subinstr local Leg1`i' "  " " ",all
		local Leg2`i': subinstr local Leg2`i' "  " " ",all
		local Leg1`i': subinstr local Leg1`i' " " ""
		local Leg2`i': subinstr local Leg2`i' " " ""
		local Leg1`i': subinstr local Leg1`i' " " ""
		local Leg2`i': subinstr local Leg2`i' " " ""
		if "`var'"=="${outcome}" local Leg1`i': subinstr local Leg1`i' " " "",all
		if "`var'"=="${outcome}" local Leg2`i': subinstr local Leg2`i' " " "",all
	}
	********************************************************

	format date %tdDDMonYYYY
	gen county10=`p100'
	gen county90=`p900'
	gen city10=`p101'
	gen city90=`p901'

	export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig2_${model}.xlsx",firstrow(variables) replace
	drop county10 county90 city10 city90

	//plots for county****************************************
	local titles `""Uppsala county, women, ages 5-14" "Uppsala county, men, ages 5-14" "Uppsala county, women, ages 15-29" "Uppsala county, men, ages 15-29" "Uppsala county, women, ages 30-49" "Uppsala county, men, ages 30-49" "Uppsala county, women, ages 50-69" "Uppsala county, men, ages 50-69" "Uppsala county, women, ages 70+" "Uppsala county, men, ages 70+""'

	forv i=1/5{
		forv j=1/2{
		gettoken tok titles:titles
		twoway (rarea LCI_Ev00 HCI_Ev00 date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort color(red%30)) /// 
		(line EventRate00 date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort lcolor(red)) ///
		(rarea LCI_Ev50 HCI_Ev50 date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort color(blue%30)) /// 
		(line EventRate50 date if agegroup==`i' & Gender==`j' & postnummer=="74010",sort lcolor(blue)) ///
		, saving("Graph`i'`j'",replace) ///
		graphregion(color(white)) legend(order(2 "`Leg10'" 4 "`Leg20'")) ytitle("Number of tests per 100,000") title("`tok'") xlabel(,angle(90)) xtitle("Date")
		}
	}
	graph combine "Graph11" "Graph12" "Graph21" "Graph22" "Graph31" "Graph32" "Graph41" "Graph42" "Graph51" "Graph52",xcommon ycommon graphregion(color(white)) iscale(*0.6)
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph`var'.png",width(2000) replace
	putdocx paragraph
	putdocx text ("`var'")
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph`var'.png"
	*******************************************************
	
	//plots for city*************************************************
	local titles `""Uppsala city, women, ages 5-14" "Uppsala city, men, ages 5-14" "Uppsala city, women, ages 15-29" "Uppsala city, men, ages 15-29" "Uppsala city, women, ages 30-49" "Uppsala city, men, ages 30-49" "Uppsala city, women, ages 50-69" "Uppsala city, men, ages 50-69" "Uppsala city, women, ages 70+" "Uppsala city, men, ages 70+""'

	format date %tdDDMonYYYY
	forv i=1/5{
		forv j=1/2{
			gettoken tok titles:titles
			twoway (rarea LCI_Ev01 HCI_Ev01 date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort color(red%30)) /// 
			(line EventRate01 date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort lcolor(red)) ///
			(rarea LCI_Ev51 HCI_Ev51 date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort color(blue%30)) /// 
			(line EventRate51 date if agegroup==`i' & Gender==`j' & postnummer=="75221",sort lcolor(blue)) ///
			, saving("Graph`i'`j'",replace) ///
			graphregion(color(white)) legend(order(2 "`Leg11'" 4 "`Leg21'")) ytitle("Number of tests per 100,000") title("`tok'") xlabel(,angle(90)) xtitle("Date")
		}
	}
	graph combine "Graph11" "Graph12" "Graph21" "Graph22" "Graph31" "Graph32" "Graph41" "Graph42" "Graph51" "Graph52",xcommon ycommon graphregion(color(white)) iscale(*0.6)
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph`var'b.png",width(2000) replace
	putdocx paragraph
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph`var'b.png"
	***********************************************************************************
	restore
}
