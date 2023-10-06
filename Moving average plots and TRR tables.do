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
			egen CutOff_ma5=filter(CutOff1),lags(-2/2) normalize coef(1 1 1 1 1) //equals 1 only if five days in a row above MA-threshold
			gen NewWave_tmp=1 if CutOff_ma5!=CutOff_ma5[_n-1] & CutOff_ma5==1 & CutOff_ma5[_n-1]!=. 
			//i.e. the start of a wave is the date where the CutOff_ma5 is 1 whereas the previous date was not.
			gen EndWave_tmp=1 if CutOff_ma5!=CutOff_ma5[_n-1] & CutOff_ma5==0 & CutOff_ma5[_n-1]!=.
			//i.e. the end of a wave is the date where the CutOff_ma5 is 0 whereas the previous date was not.
			gen Peak=sum(NewWave_tmp) //running sum
			gen EndPeak=sum(EndWave_tmp)
			gen Diff=Peak-EndPeak
			assert inrange(Diff,0,1) //asserts that the peak always start before it ends, and that it ends before the beginning of the next peak.
			drop Diff
			if "$model"=="distance_hosp" | "$model"=="distance_cases"{ 
				replace Peak=1
				replace EndPeak=0
				drop if agegroup==1 & date<date("01aug2020","DMY")
				rename *Distance *${outcome} //for code simplicity
			}
			save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Check_Moving${model}.dta",replace
			keep if Peak>EndPeak //from the start of a wave until the end.
			***********creates variables containing the max and min IRR (with CI:s) for all peaks 
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
			**************************************************************
			
			*********saves results in table**********************************
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
			*********************************************************************
			restore
		}
	}
}

//makes table more aesthetic for publication
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
