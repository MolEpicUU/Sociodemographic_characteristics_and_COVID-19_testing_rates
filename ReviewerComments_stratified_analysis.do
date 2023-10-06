/*This is the file where we show the results of the stratified model (for reviewer comments)
plus creates the supplementary figure with the raw data CNI-test associations (for 0-20th and 80-100th percentile of CNI)
*/
clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data8020.dta",replace emptyok
clear mata
clear matrix 
set matsize 5000
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear
sum Distance if area_75==1,det //3.5km median
sum Distance if area_75==0,det //24.3km median
sum CNI

local titles `""Ages 5-14" "Ages 15-29" "Ages 30-49" "Ages 50-69" "Ages 70+" "Ages 5-14" "Ages 15-29" "Ages 30-49" "Ages 50-69" "Ages 70+""'
forv i=0/1{
	forv j=1/2{
		forv k=1/5{
			gettoken ttles titles:titles
			forv z=0/1{
				preserve
					keep agegroup Gender area_75 date CNI AntalProv pop
					noi list * in 1/10
					keep if agegroup==`k' & Gender==`j' & area_75==`i'
					centile CNI,centile(20) //funkar iom att alla postkoder har lika många rader
					local c20=`=r(c_1)'
					centile CNI,centile(80)
					local c80=`=r(c_1)'
					keep if CNI<=`c20' | CNI>=`c80'
					gen CNIbin=0 if CNI<=`c20'
					replace CNIbin=1 if CNI>=`c80'
					collapse (sum) AntalProv pop,by(agegroup Gender area_75 date CNIbin)
					replace AntalProv=(AntalProv/pop)*100000 //per subgrupp för postkods-capita
					sort CNIbin date
					keep if CNIbin==`z'
					sort date
					tsset date
					egen AntalProv_ma5=filter(AntalProv),lags(-3/3) normalize coef(1 1 1 1 1 1 1)
					save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Prov`z'.dta",replace
				restore
				}
				preserve
			use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Prov0.dta",clear
			append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Prov1.dta"
			*format date %tMonYY
			twoway (line AntalProv_ma5 date if CNIbin==0,lcolor(blue)) (line AntalProv_ma5 date if CNIbin==1,lcolor(red)) ///
			,graphregion(color(white)) saving("Graph`i'`j'`k'",replace) ytitle("Number of tests per 100,000") ///
			legend(order(1 "0-20th percentile" 2 "80-100th percentile") size(*0.7)) xtitle("Date") title("`ttles'") ylabel(,angle(0)) ///
			xlabel(,format(%tdMonCCYY))
			append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data8020.dta"
			save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data8020.dta",replace
			restore
		}
	}
}

use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data8020.dta",clear
rename AntalProv_ma5 AntalProv_ma7
rename CNIbin CNI_high
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Supplementary_figure_7_Reviewer_Response.xlsx",firstrow(variables) replace

grc1leg "Graph011" "Graph012" "Graph013" "Graph014" "Graph015" ///
"Graph021" "Graph022" "Graph023" "Graph024" "Graph025",graphregion(color(white)) xcommon ycommon iscale(*0.65) title("County",size(*0.8)) cols(5) rows(2)
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\County_20_80.tif",width(2500) replace

grc1leg "Graph111" "Graph112" "Graph113" "Graph114" "Graph115" ///
"Graph121" "Graph122" "Graph123" "Graph124" "Graph125",graphregion(color(white)) xcommon ycommon iscale(*0.65) title("City",size(*0.8)) cols(5) rows(2)
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\City_20_80.tif",width(2500) replace

clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data_stratified_predictions.dta",replace emptyok
clear mata
clear matrix 
set matsize 5000
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear
sum Distance if area_75==1,det //3.5km median
sum Distance if area_75==0,det //24.3km median
sum CNI
**********************This is the part for generating the model(s).
//Different models for distance, adj. for hospitalizations and adj. for positive tests.
//The models are slow, so it's worth commenting away the "if"-parts and the "estimate save" once the models have been generated, 
//only running the "estimates use" command
*if "$model"=="hospitalizations" poisson AntalProv i.agegroup##c.date_spl*##c.${outcome}##i.Gender##i.area_75 PatSpline* i.weekday if pop!=0, irr exposure(pop) vce(cluster postnummer_num)
*estimates save "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}",replace
*estimates use "C:\Users\ulfha881\PROJECTS\Tove\MyData\Est${model}${outcome}"


*local titles `""Women, ages 5-14" "Women, ages 15-29" "Women, ages 30-49" "Women, ages 50-69" "Women, ages 70+" "Men, ages 5-14" "Men, ages 15-29" "Men, ages 30-49" "Men, ages 50-69" "Men, ages 70+""'
local titles `""Uppsala county, women, ages 5-14" "Uppsala county, men, ages 5-14" "Uppsala county, women, ages 15-29" "Uppsala county, men, ages 15-29" "Uppsala county, women, ages 30-49" "Uppsala county, men, ages 30-49" "Uppsala county, women, ages 50-69" "Uppsala county, men, ages 50-69" "Uppsala county, women, ages 70+" "Uppsala county, men, ages 70+""'
local titles2 `""Uppsala city, women, ages 5-14" "Uppsala city, men, ages 5-14" "Uppsala city, women, ages 15-29" "Uppsala city, men, ages 15-29" "Uppsala city, women, ages 30-49" "Uppsala city, men, ages 30-49" "Uppsala city, women, ages 50-69" "Uppsala city, men, ages 50-69" "Uppsala city, women, ages 70+" "Uppsala city, men, ages 70+""'

global outcome "CNI"
*sum AntalpatienterPer100000
*replace AntalpatienterPer100000=`=r(mean)'

levelsof agegroup,local(agr)
levelsof Gender,local(gndr)
levelsof area_75,local(a75)
*gen common_cold_period=(date>date("20210801","YMD") & date<date("20211201","YMD"))
//THIS GENERATES MODEL-BASED GRAPHS FOR EVENTS (per 100,000)

foreach v1 of local agr{
	foreach v2 of local gndr{
		foreach v3 of local a75{
		sum CNI if area_75==0,det
		local p100=`=r(p10)'
		local p900=`=r(p90)'
		sum CNI if area_75==1,det
		local p101=`=r(p10)'
		local p901=`=r(p90)'
		preserve
		keep if agegroup==`v1' & Gender==`v2' & area_75==`v3'
			*poisson AntalProv c.date_spl* /*##c.CNI*/  /*i.weekday*/ if pop!=0 & agegroup==`v1' & Gender==`v2' & area_75==`v3', irr exposure(pop) vce(cluster postnummer_num)
			poisson AntalProv c.date_spl*##c.CNI c.PosSpline* i.weekday if pop!=0 & agegroup==`v1' & Gender==`v2' & area_75==`v3', irr exposure(pop) vce(cluster postnummer_num) 
		*replace common_cold_period=0
		replace pop=100000 if agegroup==`v1' & Gender==`v2' & area_75==`v3'
		replace Vaccin_rate2=0 if agegroup==`v1' & Gender==`v2' & area_75==`v3'

		forv spl=1/3{
			replace PosSpline`spl'=0 if agegroup==`v1' & Gender==`v2' & area_75==`v3'
			replace PatSpline`spl'=0 if agegroup==`v1' & Gender==`v2' & area_75==`v3'
		}
		replace weekday=3 if agegroup==`v1' & Gender==`v2' & area_75==`v3'
			forv i=0/1{
				if "CNI"=="Distance"{
					sum ${outcome}
					replace ${outcome}=`=r(mean)'
				}
				replace CNI=`p10`i''
				local perc_10`i': di %9.2f `p10`i''
				local perc_90`i': di %9.2f `p90`i''
				
				predict EventRate0`i',xb
				predict se0`i',stdp
				replace CNI=`p90`i''
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

		if "CNI"=="${outcome}"{
			local Leg10 "${outcome}=`perc_100'"
			local Leg20 "${outcome}=`perc_900'"
			local Leg11 "${outcome}=`perc_101'"
			local Leg21 "${outcome}=`perc_901'"
		}
		if "CNI"=="Distance"{
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
			if "CNI"=="${outcome}" local Leg1`i': subinstr local Leg1`i' " " "",all
			if "CNI"=="${outcome}" local Leg2`i': subinstr local Leg2`i' " " "",all
		}

		format date %tdDDMonYYYY
			if `v3'==0{
				gettoken tok titles:titles
				twoway (rarea LCI_Ev00 HCI_Ev00 date if agegroup==`v1' & Gender==`v2' & postnummer=="74010",sort color(blue%30)) /// 
				(line EventRate00 date if agegroup==`v1' & Gender==`v2' & postnummer=="74010",sort lcolor(blue)) ///
				(rarea LCI_Ev50 HCI_Ev50 date if agegroup==`v1' & Gender==`v2' & postnummer=="74010",sort color(red%30)) /// 
				(line EventRate50 date if agegroup==`v1' & Gender==`v2' & postnummer=="74010",sort lcolor(red)) ///
				, saving("Graph`v1'`v2'_county",replace) ///
				graphregion(color(white)) legend(order(2 "`Leg10'" 4 "`Leg20'")) ytitle("Number of tests per 100,000") title("`tok'") xlabel(,angle(90)) xtitle("Date")
			}

		format date %tdDDMonYYYY
			if `v3'==1{
				gettoken tok titles2:titles2
				twoway (rarea LCI_Ev01 HCI_Ev01 date if agegroup==`v1' & Gender==`v2' & postnummer=="75221",sort color(blue%30)) /// 
				(line EventRate01 date if agegroup==`v1' & Gender==`v2' & postnummer=="75221",sort lcolor(blue)) ///
				(rarea LCI_Ev51 HCI_Ev51 date if agegroup==`v1' & Gender==`v2' & postnummer=="75221",sort color(red%30)) /// 
				(line EventRate51 date if agegroup==`v1' & Gender==`v2' & postnummer=="75221",sort lcolor(red)) ///
				, saving("Graph`v1'`v2'_city",replace) ///
				graphregion(color(white)) legend(order(2 "`Leg11'" 4 "`Leg21'")) ytitle("Number of tests per 100,000") title("`tok'") xlabel(,angle(90)) xtitle("Date")
			}
			append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data_stratified_predictions.dta"
			save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Data_stratified_predictions.dta",replace
		restore
		}
	}
}

/*
graph combine "Graph11_city" "Graph12_city" "Graph21_city" "Graph22_city" "Graph31_city" "Graph32_city" ///
"Graph41_city" "Graph42_city" "Graph51_city" "Graph52_city",xcommon ycommon graphregion(color(white)) iscale(*0.6)
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph_city.png",width(2000) replace

graph combine "Graph11_county" "Graph12_county" "Graph21_county" "Graph22_county" ///
"Graph31_county" "Graph32_county" "Graph41_county" "Graph42_county" ///
"Graph51_county" "Graph52_county",xcommon ycommon graphregion(color(white)) iscale(*0.6)
graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Graph_county.png",width(2000) replace
