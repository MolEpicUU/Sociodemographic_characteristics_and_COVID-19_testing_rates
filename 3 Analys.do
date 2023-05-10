/*This is the file where 
1)the regression models are run 
2)plots and data for TRR and marginal effects are created.
3)the difference-in-difference analysis is run
4)The tables with min- and max-TRR per pandemic period is created
*/
clear
clear mata
clear matrix 
set matsize 5000
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear

**********************This is the part for generating the model(s).
//Different models for distance, adj. for hospitalizations and adj. for positive tests.
//The models are slow, so it's worth commenting away the "if"-parts and the "estimate save" once the models have been generated, 
//only running the "estimates use" command
if "$model"=="distance_hosp" | "$model"=="distance_cases"{ 
	drop if date>date("12oct2020","DMY")
	drop date_spl*
	gen date_spl1=date_0
	if "$model"=="distance_hosp" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 i.agegroup##c.date_spl*##c.Distance##i.Gender##i.area_75 PatSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
	if "$model"=="distance_cases" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 i.agegroup##c.date_spl*##c.Distance##i.Gender##i.area_75 PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
}

if "$model"=="crude" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)

if "$model"=="hospitalizations" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 PatSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
if "$model"=="cases" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
estimates save "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}",replace
estimates use "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}"

if "$model"=="distance_hosp" | "$model"=="distance_cases" local variab "Distance"
if ("$model"=="hospitalizations" | "$model"=="cases" | "$model"=="crude") local variab "${outcome}"

local titles `""Women, ages 5-14" "Women, ages 15-29" "Women, ages 30-49" "Women, ages 50-69" "Women, ages 70+" "Men, ages 5-14" "Men, ages 15-29" "Men, ages 30-49" "Men, ages 50-69" "Men, ages 70+""'

sum AntalpatienterPer100000
replace AntalpatienterPer100000=`=r(mean)'

if "$model"=="distance_hosp" | "$model"=="distance_cases" local variab "Distance"
if ("$model"=="hospitalizations" | "$model"=="cases") local variab "${outcome}"
**************************************************************
//the long chunk that follows generates p-values for each of the sub-plots in the marginal effects graphs
cap postclose myfile
postfile myfile area gender agegroup pval estim lb ub using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\pvalues${model}CNI.dta",replace

if ("$model"=="distance_cases" | "$model"=="distance_hospitalizations"){
	local ticker=0
	local add ""
	local var "`variab'"
	di "`var'"
	forv agegroup=1/5{
		forv Gender=1/2{
			forv a75=0/1{		
				test c.`var' /// main effect
				c.`var'#`agegroup'.agegroup ///
				c.`var'#`Gender'.Gender ///
				c.`var'#`a75'.area_75 /// two-way interactions
				c.`var'#`a75'.area_75#`Gender'.Gender ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup ///
				c.`var'#`agegroup'.agegroup#`Gender'.Gender /// 
				c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup ///
				c.`var'#c.date_spl1 ///
				c.`var'#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`Gender'.Gender#c.date_spl1 ///
				c.`var'#`a75'.area_75#c.date_spl1 ///
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1 ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1 `add' /* five-way interactions*/
				local ticker=`ticker'+1
				if `ticker'!=0 local add ",accum"
			}
		}
	}
	post myfile (.) (.) (.) (`=r(p)') (.) (.) (.)

	forv agegroup=1/5{
		forv Gender=1/2{
			forv a75=0/1{		
				test (c.`var'+ /// main effect
				c.`var'#`agegroup'.agegroup+ ///
				c.`var'#`Gender'.Gender+ ///
				c.`var'#`a75'.area_75+ /// two-way interactions
				c.`var'#`a75'.area_75#`Gender'.Gender+ ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup+ ///
				c.`var'#`agegroup'.agegroup#`Gender'.Gender+ /// 
				c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup=0) ///
				(c.`var'#c.date_spl1+ ///
				c.`var'#`agegroup'.agegroup#c.date_spl1+ ///
				c.`var'#`Gender'.Gender#c.date_spl1+ ///
				c.`var'#`a75'.area_75#c.date_spl1+ ///
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1+ ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1+ ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1+ ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1=0) /* five-way interactions*/
				post myfile (`a75') (`Gender') (`agegroup') (`=r(p)') (.) (.) (.)
			}
		}
	}
	postclose myfile
}

if "$model"!="distance_cases" & "$model"!="distance_hospitalizations"{
	local ticker=0
	local add ""
	local var "`variab'"
	forv agegroup=1/5{
		forv Gender=1/2{
			forv a75=0/1{		
				test c.`var' /// main effect
				c.`var'#`agegroup'.agegroup ///
				c.`var'#`Gender'.Gender ///
				c.`var'#`a75'.area_75 /// two-way interactions
				c.`var'#`a75'.area_75#`Gender'.Gender ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup ///
				c.`var'#`agegroup'.agegroup#`Gender'.Gender /// 
				c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup ///
				c.`var'#c.date_spl1 ///
				c.`var'#c.date_spl2 ///
				c.`var'#c.date_spl3 ///
				c.`var'#c.date_spl4 ///
				c.`var'#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`agegroup'.agegroup#c.date_spl2 ///
				c.`var'#`agegroup'.agegroup#c.date_spl3 ///
				c.`var'#`agegroup'.agegroup#c.date_spl4 ///
				c.`var'#`Gender'.Gender#c.date_spl1 ///
				c.`var'#`Gender'.Gender#c.date_spl2 ///
				c.`var'#`Gender'.Gender#c.date_spl3 ///
				c.`var'#`Gender'.Gender#c.date_spl4 ///
				c.`var'#`a75'.area_75#c.date_spl1 ///
				c.`var'#`a75'.area_75#c.date_spl2 ///
				c.`var'#`a75'.area_75#c.date_spl3  ///
				c.`var'#`a75'.area_75#c.date_spl4 /// three-way interactions
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1 ///
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl2 ///
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl3 ///
				c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl4 ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl2 ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl3 ///
				c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl4 ///	
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl2 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl3 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl4 /// four-way interactions
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1  ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl2 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl3 ///
				c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl4 `add' /* five-way interactions*/
				local ticker=`ticker'+1
				if `ticker'!=0 local add ",accum"
			}
		}
	}
	post myfile (.) (.) (.) (`=r(p)') (.) (.) (.)

	forv agegroup=1/5{
		forv Gender=1/2{
			forv a75=0/1{		
				*local ticker=0
				*local add ""
				test (c.`var'+ /// main effect
					c.`var'#`agegroup'.agegroup+ ///
					c.`var'#`Gender'.Gender+ ///
					c.`var'#`a75'.area_75+ /// two-way interactions
					c.`var'#`a75'.area_75#`Gender'.Gender+ ///
					c.`var'#`a75'.area_75#`agegroup'.agegroup+ ///
					c.`var'#`agegroup'.agegroup#`Gender'.Gender+ /// 
					c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup=0)
					if (`agegroup'!=1 & `Gender'!=1 & `a75'!=0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`agegroup'.agegroup#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl`z'+ ///	
								c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl`z'=0), accum /* five-way interactions*/
							}
					}
					if (`agegroup'!=1 & `Gender'!=1 & `a75'==0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`agegroup'.agegroup#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl`z'=0), accum /* five-way interactions*/
							}
					}
					if (`agegroup'!=1 & `Gender'==1 & `a75'!=0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`agegroup'.agegroup#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl`z'=0), accum /* five-way interactions*/
							}
					}
					if (`agegroup'!=1 & `Gender'==1 & `a75'==0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`agegroup'.agegroup#c.date_spl`z'=0), accum /* five-way interactions*/
							}
					}
					if (`agegroup'==1 & `Gender'!=1 & `a75'!=0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#`a75'.area_75#c.date_spl`z'=0), accum /* five-way interactions*/
							}
					}
					if (`agegroup'==1 & `Gender'==1 & `a75'!=0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`a75'.area_75#c.date_spl`z'=0), accum
							}
					}
					if (`agegroup'==1 & `Gender'!=1 & `a75'==0){
						forv z=1/4{
								test (c.`var'#c.date_spl`z'+ ///
								c.`var'#`Gender'.Gender#c.date_spl`z'=0), accum
							}
					}
					if (`agegroup'==1 & `Gender'==1 & `a75'==0){
					forv z=1/4{
						test (c.`var'#c.date_spl`z'=0),accum
						}
					}
					post myfile (`a75') (`Gender') (`agegroup') (`=r(p)') (.) (.) (.)
				}
			}
		}
		postclose myfile
	}


preserve
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\pvalues${model}CNI.dta",clear
tostring area gender agegroup,replace
replace area="City" if area=="1"
replace area="County" if area=="0"
replace gender="Female" if gender=="1"
replace gender="Male" if gender=="2"
replace agegroup="Ages 5-14" if agegroup=="1"
replace agegroup="Ages 15-29" if agegroup=="2"
replace agegroup="Ages 30-49" if agegroup=="3"
replace agegroup="Ages 50-69" if agegroup=="4"
replace agegroup="Ages 70+" if agegroup=="5"
replace area="OMNIBUS" if area=="."
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\pvalues${model}CNI_clean.xlsx",firstrow(variables) replace
restore
*****************************************************************************

//THIS GENERATES MODEL-BASED GRAPHS FOR EVENTS (per 100,000)
foreach var of local variab{
preserve
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
	forv i=0/1{
		if "`var'"=="Distance"{
			sum ${outcome}
			replace ${outcome}=`=r(mean)'
		}
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
keep if postnummer=="74010" | postnummer=="75221" //we need one postal code from Uppsala City and one code from Uppsala County for generating the plots

local titles `""Uppsala county, women, ages 5-14" "Uppsala county, men, ages 5-14" "Uppsala county, women, ages 15-29" "Uppsala county, men, ages 15-29" "Uppsala county, women, ages 30-49" "Uppsala county, men, ages 30-49" "Uppsala county, women, ages 50-69" "Uppsala county, men, ages 50-69" "Uppsala county, women, ages 70+" "Uppsala county, men, ages 70+""'

if "`var'"=="${outcome}"{
	local Leg10 "${outcome}=`perc_100'"
	local Leg20 "${outcome}=`perc_900'"
	local Leg11 "${outcome}=`perc_101'"
	local Leg21 "${outcome}=`perc_901'"
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

format date %tdDDMonYYYY
gen county10=`p100'
gen county90=`p101'
gen city10=`p900'
gen city90=`p901'

export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig2_${model}.xlsx",firstrow(variables) replace
drop county10 county90 city10 city90

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
restore
}

**************************This chunk is for generating the TRR:s*******************************************
foreach var of local variab{
preserve

keep if postnummer=="74010" | postnummer=="75221"
replace pop=100000

gen IRR`var'=.
gen LCI`var'=.
gen HCI`var'=.
gen z`var'=.
count
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

	if "$model"=="distance_hosp" | "$model"=="distance_cases"{ 
		lincom `var'+ /// main effect
		c.`var'#`agegroup'.agegroup+ ///
		c.`var'#`Gender'.Gender+ ///
		c.`var'#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75+ /// two-way interactions
		c.`var'#`a75'.area_75#`Gender'.Gender+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup+ ///
		c.`var'#`agegroup'.agegroup#`Gender'.Gender+ /// 
		c.`var'#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#`agegroup'.agegroup+ ///
		c.`var'#`a75'.area_75#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
		c.`var'#`a75'.area_75#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.`var'#`Gender'.Gender#`agegroup'.agegroup#`a75'.area_75#c.date_spl1*`dspl1',eform /* five-way interactions*/
	}
	
	replace IRR`var'=`=r(estimate)'  in `i'
	replace LCI`var'=`=r(lb)' in `i' 
	replace HCI`var'=`=r(ub)' in `i'
	replace z`var'=`=r(z)' in `i'
}

if "`variab'"=="Distance" local ylbel "0.9 0.95 1 1.05"
if "`variab'"=="${outcome}" local ylbel "0.5 0.75 1 1.5 2"

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

local titles `""Uppsala city, ages 5-14" "Uppsala city, men, ages 5-14" "Uppsala city, women, ages 15-29" "Uppsala city, men, ages 15-29" "Uppsala city, women, ages 30-49" "Uppsala city, men, ages 30-49" "Uppsala city, women, ages 50-69" "Uppsala city, men, ages 50-69" "Uppsala city, women, ages 70+" "Uppsala city, men, ages 70+""'
forv i=1/5{
	forv j=1/2{
	gettoken tok titles:titles
	*putdocx text ("`var'")
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

**********This is the difference-in-difference analysis for Gottsunda and Sävja***********
if "$model"=="cases"{
	preserve
	keep if Cat=="Gottsunda" | Cat=="Sävja"
	gen Intervention=(date>date("11oct2020","DMY")) //Teststation, Gottsunda
	replace Intervention=0 if Cat=="Sävja"

	collapse (sum) AntalProv pop Antalpositivaprov (first) Antalpatienter,by(Cat date_spl* Intervention Cat Gender agegroup date weekday)
	gen AntalpatienterPer100000=Antalpatienter/pop*100000
	gen AntalPositivaPer100000=Antalpositivaprov/pop*100000
	mkspline PatSpline=AntalpatienterPer100000,knots(-10 35 75 200) cubic
	mkspline PosSpline=AntalPositivaPer100000,knots(-10 500 2000 40000) cubic
	encode Cat,gen(Cat_num)

	poisson AntalProv i.agegroup##c.date_spl*##c.Intervention##i.Gender i.Cat_num i.agegroup i.Gender PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(robust) /*vce(cluster NewClust)*/

	test c.Intervention c.Intervention#2.agegroup c.Intervention#3.agegroup c.Intervention#4.agegroup c.Intervention#5.agegroup ///
	c.Intervention#2.Gender c.Intervention#c.date_spl1  ///
	c.Intervention#c.date_spl2 c.Intervention#c.date_spl3 c.Intervention#c.date_spl4  ///
	c.Intervention#2.agegroup#c.date_spl1 c.Intervention#3.agegroup#c.date_spl1 c.Intervention#4.agegroup#c.date_spl1 c.Intervention#5.agegroup#c.date_spl1  ///
	c.Intervention#2.agegroup#c.date_spl2 c.Intervention#3.agegroup#c.date_spl2 c.Intervention#4.agegroup#c.date_spl2 c.Intervention#5.agegroup#c.date_spl2  ///
	c.Intervention#2.agegroup#c.date_spl3 c.Intervention#3.agegroup#c.date_spl3 c.Intervention#4.agegroup#c.date_spl3 c.Intervention#5.agegroup#c.date_spl3 ///
	c.Intervention#2.agegroup#c.date_spl4 c.Intervention#3.agegroup#c.date_spl4 c.Intervention#4.agegroup#c.date_spl4 c.Intervention#5.agegroup#c.date_spl4 ///
	c.Intervention#2.Gender#c.date_spl1 ///
	c.Intervention#2.Gender#c.date_spl2 ///
	c.Intervention#2.Gender#c.date_spl3 ///
	c.Intervention#2.Gender#c.date_spl4 ///
	c.Intervention#2.Gender#2.agegroup#c.date_spl1 c.Intervention#2.Gender#3.agegroup#c.date_spl1 c.Intervention#2.Gender#4.agegroup#c.date_spl1 c.Intervention#2.Gender#5.agegroup#c.date_spl1 ///
	c.Intervention#2.Gender#2.agegroup#c.date_spl2 c.Intervention#2.Gender#3.agegroup#c.date_spl2 c.Intervention#2.Gender#4.agegroup#c.date_spl2 c.Intervention#2.Gender#5.agegroup#c.date_spl2 ///
	c.Intervention#2.Gender#2.agegroup#c.date_spl3 c.Intervention#2.Gender#3.agegroup#c.date_spl3 c.Intervention#2.Gender#4.agegroup#c.date_spl3 c.Intervention#2.Gender#5.agegroup#c.date_spl3 ///
	c.Intervention#2.Gender#2.agegroup#c.date_spl4 c.Intervention#2.Gender#3.agegroup#c.date_spl4 c.Intervention#2.Gender#4.agegroup#c.date_spl4 c.Intervention#2.Gender#5.agegroup#c.date_spl4

	local p: di %9.3f `=r(p)'
	putdocx paragraph
	putdocx text ("The omnibus p-value for the intervention effect is `p'")

	gen IRR=.
	gen LCI=.
	gen HCI=.

	gen pval=.
	
	forv spl=1/3{
		replace PosSpline`spl'=0
		replace PatSpline`spl'=0
	}
	replace weekday=3
	replace pop=100000
	
	predict EventRate,xb
	predict se,stdp
	
	gen LCI_Ev=EventRate+invnormal(0.025)*se
	gen HCI_Ev=EventRate+invnormal(0.975)*se
	replace LCI_Ev=exp(LCI_Ev)
	replace HCI_Ev=exp(HCI_Ev)
	replace EventRate=exp(EventRate)
	
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Fig4_tmp.dta",replace
	drop LCI_Ev HCI_Ev EventRate se
	
	keep if Cat=="Gottsunda"
	keep if date>date("11oct2020","DMY")
	
	count
	forv i=1/`=r(N)'{
		local agegroup=agegroup[`i']
		local Gender=Gender[`i']
		local dspl1=date_spl1[`i']
		local dspl2=date_spl2[`i']
		local dspl3=date_spl3[`i']
		local dspl4=date_spl4[`i']
	
		lincom c.Intervention+ /// main effect
		c.Intervention#`agegroup'.agegroup+ ///
		c.Intervention#`Gender'.Gender+ ///
		c.Intervention#c.date_spl1*`dspl1'+ ///
		c.Intervention#c.date_spl2*`dspl2'+ ///
		c.Intervention#c.date_spl3*`dspl3'+ ///
		c.Intervention#c.date_spl4*`dspl4'+ ///
		c.Intervention#`agegroup'.agegroup#`Gender'.Gender+ /// 
		c.Intervention#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.Intervention#`agegroup'.agegroup#c.date_spl2*`dspl2'+ ///
		c.Intervention#`agegroup'.agegroup#c.date_spl3*`dspl3'+ ///
		c.Intervention#`agegroup'.agegroup#c.date_spl4*`dspl4'+ ///
		c.Intervention#`Gender'.Gender#c.date_spl1*`dspl1'+ ///
		c.Intervention#`Gender'.Gender#c.date_spl2*`dspl2'+ ///
		c.Intervention#`Gender'.Gender#c.date_spl3*`dspl3'+ ///
		c.Intervention#`Gender'.Gender#c.date_spl4*`dspl4'+ ///
		c.Intervention#`Gender'.Gender#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.Intervention#`Gender'.Gender#`agegroup'.agegroup#c.date_spl2*`dspl2'+ ///
		c.Intervention#`Gender'.Gender#`agegroup'.agegroup#c.date_spl3*`dspl3'+ ///
		c.Intervention#`Gender'.Gender#`agegroup'.agegroup#c.date_spl4*`dspl4',eform

		replace IRR=`=r(estimate)'  in `i'
		replace LCI=`=r(lb)' in `i' 
		replace HCI=`=r(ub)' in `i'
	}

		local titles `""Intervention, women, ages 5-14" "Intervention, men, ages 5-14" "Intervention, women, ages 15-29" "Intervention, men, ages 15-29" "Intervention, women, ages 30-49" "Intervention, men, ages 30-49" "Intervention, women, ages 50-69" "Intervention, ages 50-69" "Intervention, women, ages 70+" "Intervention, men, ages 70+""'
		format date %tdDDMonCCYY
		merge 1:1 Cat agegroup Gender date using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Fig4_tmp.dta",nogenerate
		export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_${model}.xlsx",firstrow(variables) replace
		
		forv i=1/5{
			forv j=1/2{
			gettoken tok titles:titles
			twoway (rarea LCI`var' HCI`var' date if agegroup==`i' & Gender==`j',sort color(gs10)) /// 
			(line IRR`var' date if agegroup==`i' & Gender==`j',sort lcolor(black)), saving("Graph`i'`j'",replace) ///
			graphregion(color(white)) legend(off) ytitle("Incidence rate ratio") ylabel(0.5 1 2 5 10 15)  title("`tok'") xlabel(,angle(90)) xtitle("Date") yscale(log) ylabel(,angle(0)) yline(1,lcolor(red))
			}
		}
		graph combine "Graph11" "Graph12" "Graph21" "Graph22" "Graph31" "Graph32" "Graph41" "Graph42" "Graph51" "Graph52",xcommon ycommon graphregion(color(white)) iscale(*0.7)
		
		graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\GraphGottsunda.png",width(2000) replace
		putdocx paragraph
		putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\GraphGottsunda.png"
	restore
}
********************************

//This chunk is for 1)generating the moving average-plots
//2) Generating the tables with maximum and minimum TRR within each covid-19 peak-period
foreach k in 14{
//MA-plots
clear
save "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable_complete.dta",replace emptyok
use "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable.dta",clear
format date %td
if "$model"=="cases"{
	twoway line pos_tot_ma14 date,sort yline(500,lcolor(red)) graphregion(color(white)) ylabel(500 1000 1500 2000) xtitle("Date") ytitle("Number of positive tests per 100,000" "(14-day moving sum)") ///
	xlabel(22111 `""Jul" "2020""' ///
	22295 `""Jan" "2021""' 22476 `""Jul" "2021""' 22660 `""Jan" "2022""')
	graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MA14.png",width(2000) replace
	putdocx paragraph
	putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MA14.png"
}


//Generating tables
gen CutOff1=pos_tot_ma14>500
replace CutOff1=. if pos_tot_ma14==.

//loops over city/county, gender and agegroup. CutOff_ma5==1 means that five days in a row has been above the moving average-threshold.
//CutOff_ma5==0 means that five days in a row has been below the threshold. So NewWave_tmp denotes the start of a peak, EndWave_tmp the end of a peak.
forv i=0/1{
forv z=1/2{
	forv j=1/5{
		preserve
		isid area_75 Gender agegroup date
		sort area_75 Gender agegroup date
		gettoken tok titles:titles
		keep if Gender==`z' & agegroup==`j' & area_75==`i'
		egen CutOff_ma5=filter(CutOff1),lags(-2/2) normalize coef(1 1 1 1 1)
		gen NewWave_tmp=1 if CutOff_ma5!=CutOff_ma5[_n-1] & CutOff_ma5==1 & CutOff_ma5[_n-1]!=.
		gen EndWave_tmp=1 if CutOff_ma5!=CutOff_ma5[_n-1] & CutOff_ma5==0 & CutOff_ma5[_n-1]!=.
		gen Peak=sum(NewWave_tmp) //running sum
		gen EndPeak=sum(EndWave_tmp)
		gen Diff=Peak-EndPeak
		assert inrange(Diff,0,1) //asserts that the peak always start before it ends, and that it ends before the beginning of the next peak.
		drop Diff
		if "$model"=="distance_hosp" | "$model"=="distance_cases"{ 
			replace Peak=1
			replace EndPeak=0
			rename *Distance *${outcome} //for code simplicity
		}
		keep if Peak>EndPeak
		egen Max=max(IRR${outcome}),by(Peak)
		egen Min=min(IRR${outcome}),by(Peak)
		gen MaxHCI_tmp=HCI${outcome} if Max==IRR${outcome}
		gen MinHCI_tmp=HCI${outcome} if Min==IRR${outcome}
		gen MaxLCI_tmp=LCI${outcome} if Max==IRR${outcome}
		gen MinLCI_tmp=LCI${outcome} if Min==IRR${outcome}
		gen DateOfMax_tmp=date if Max==IRR${outcome}
		gen DateOfMin_tmp=date if Min==IRR${outcome}
		egen StartDate=min(date),by(Peak)
		egen EndDate=max(date),by(Peak)
		keep MaxHCI_tmp MinHCI_tmp MaxLCI_tmp MinLCI_tmp DateOfMax_tmp DateOfMin_tmp Max Min Peak Gender agegroup StartDate EndDate area_75
		foreach var of varlist *tmp{
			egen `var'_touse=max(`var'),by(Peak)
			drop `var'
		}
		rename *_tmp_touse *
		duplicates drop
		if ("$model"=="hospitalizations" | "$model"=="cases" | "$model"=="crude"){
			gen EstCI_max=string(Max,"%9.2f")+" ("+string(MaxLCI,"%9.2f")+", "+string(MaxHCI,"%9.2f")+")"
			gen EstCI_min=string(Min,"%9.2f")+" ("+string(MinLCI,"%9.2f")+", "+string(MinHCI,"%9.2f")+")"
		}
		if ("$model"=="distance_hosp" | "$model"=="distance_cases"){
			gen EstCI_max=string(Max,"%9.3f")+" ("+string(MaxLCI,"%9.3f")+", "+string(MaxHCI,"%9.3f")+")"
			gen EstCI_min=string(Min,"%9.3f")+" ("+string(MinLCI,"%9.3f")+", "+string(MinHCI,"%9.3f")+")"
		}
		gen Group="`tok'"
		keep EstCI* Date* Group agegroup Gender Peak StartDate EndDate area_75
		append using "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable_complete.dta"
		save "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable_complete.dta",replace
		restore
	}
}
}

use "C:\Users\ulfha881\PROJECTS\Tove\MyData\MovingAveragesTable_complete.dta",clear
isid Peak Gender agegroup area_75
sort Peak Gender agegroup area_75
keep EstCI_max EstCI_min Peak area_75 Gender agegroup
reshape wide EstCI*,i(Gender agegroup area_75) j(Peak)
reshape wide EstCI*,i(Gender agegroup) j(area_75)

gen Category=""
replace Category="Women, ages 5-14" if agegroup==1 & Gender==1
replace Category="Women, ages 15-29" if agegroup==2 & Gender==1
replace Category="Women, ages 30-49" if agegroup==3 & Gender==1
replace Category="Women, ages 50-69" if agegroup==4 & Gender==1
replace Category="Women, ages 70+" if agegroup==5 & Gender==1
replace Category="Men, ages 5-14" if agegroup==1 & Gender==2
replace Category="Men, ages 15-29" if agegroup==2 & Gender==2
replace Category="Men, ages 30-49" if agegroup==3 & Gender==2
replace Category="Men, ages 50-69" if agegroup==4 & Gender==2
replace Category="Men, ages 70+" if agegroup==5 & Gender==2
sort agegroup Gender
drop Gender agegroup
gen n=_n
expand 5 if n==1
sort n
drop n
tostring *,replace
foreach var of varlist EstCI_max*{
	replace `var'="Highest TRR (95% CI)" if _n==4
}
foreach var of varlist EstCI_min*{
	replace `var'="Lowest TRR (95% CI)" if _n==4
}	
order Category,first
if "$model"=="hospitalizations" | "$model"=="cases" order Category EstCI_max11 EstCI_min11 EstCI_max10 EstCI_min10 EstCI_max21 EstCI_min21 EstCI_max20 EstCI_min20 EstCI_max31 EstCI_min31 EstCI_max30 EstCI_min30 
foreach var of varlist *{
	replace `var'="" if _n==1 | _n==2 | _n==3
}
replace Category="" if _n==4
foreach var of varlist *max*1{
	replace `var'="Uppsala city" if _n==3
}
foreach var of varlist *max*0{
	replace `var'="Uppsala county" if _n==3
}
if "$model"=="hospitalizations" | "$model"=="cases"{
	foreach var of varlist EstCI_max10{
		replace `var'="Second pandemic wave" if _n==1 
		replace `var'="Nov 12 2020-Jan 5 2021" if _n==2
	}
	foreach var of varlist EstCI_max20{
		replace `var'="Third pandemic wave" if _n==1
		replace `var'="Mar 20 2020-May 5 2021" if _n==2
	}
	foreach var of varlist EstCI_max30{
		replace `var'="Fourth pandemic wave" if _n==1
		replace `var'="January 2 2022-February 9 2022" if _n==2
	}
}
if "$model"=="distance_hosp" | "$model"=="distance_cases"{
	foreach var of varlist EstCI_max10{
		replace `var'="" if _n==1 
		replace `var'="June 24 2020-Oct 11 2020" if _n==2
	}
}

putdocx sectionbreak, landscape
putdocx paragraph,font("",10)
putdocx text ("Estimates table for abstract. `k' days moving sum")
putdocx table esttabl=data(.)

local c=0
count
foreach a of varlist *{
	local c=`c'+1
	forv b=1/`=r(N)'{
	if (strpos(`a'[`b'],"(1.") & strpos(`a'[`b'],", 1.")){
		putdocx table esttabl(`b',`c'),bold
	}
	if (strpos(`a'[`b'],"(0.") & strpos(`a'[`b'],", 0.")){
		putdocx table esttabl(`b',`c'),bold
	}
	}
}
}
**********************************************************
