use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear
putdocx paragraph
**********This is the difference-in-difference analysis for Gottsunda and Sävja***********
//also generates TRR graphs, in similar style as the main analysis.
if "$model"=="cases"{
	//calculates number of individuals in Gottsunda/Sävja
	preserve
	keep if Cat=="Gottsunda" | Cat=="Sävja"
	keep if date==date("12oct2020","DMY") /*11928 Gottsunda, 4115 Sävja*/
	collapse (sum) population,by(Cat)
	sort Cat
	local p1=pop[1]
	local p2=pop[2]
	putdocx text ("The number of individuals in Gottsunda is: `p1'")
	putdocx text ("The number of individuals in Sävja is: `p2'")
	restore
	
	//calculates number of tests in Gottsunda/Sävja during the 3 months post-intervention
	preserve
	keep if Cat=="Gottsunda" | Cat=="Sävja"
	keep if (date<=(date("12oct2020","DMY")+90) & (date>=(date("12oct2020","DMY"))))
	collapse (sum) AntalProv,by(Cat)
	sort Cat
	local p1=AntalProv[1]
	local p2=AntalProv[2]
	putdocx text ("The no of tests in Gottsunda 3m after 12oct2020 is: `p1'")
	putdocx text ("The no of tests in Sävja 3m after 12oct2020 is: `p2'")
	restore
	
	preserve
	keep if Cat=="Gottsunda" | Cat=="Sävja"
	keep if (date<=(date("12oct2020","DMY")+90) & (date>=(date("12oct2020","DMY")-90))) //90 days before and after intervention
	export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Temporary_file.xlsx",firstrow(variables) replace
	drop *_spl*
	mkspline date_spl=date_0,nknots(3) cubic displayknots
	gen Intervention=(date>date("11oct2020","DMY")) //Teststation, Gottsunda
	replace Intervention=0 if Cat=="Sävja"
	
	collapse (sum) AntalProv pop Antalpositivaprov (first) Antalpatienter,by(Cat date_spl* Intervention Gender agegroup date weekday)
	gen AntalpatienterPer100000=Antalpatienter/pop*100000
	gen AntalPositivaPer100000=Antalpositivaprov/pop*100000
	mkspline PatSpline=AntalpatienterPer100000,knots(-10 35 75 200) cubic
	mkspline PosSpline=AntalPositivaPer100000,knots(-10 500 2000 40000) cubic
	encode Cat,gen(Cat_num)
	
	save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Temporary_file2.dta",replace //we want to drop the youngest before 1st aug in the analysis
	drop if agegroup==1 & date<date("01aug2020","DMY")
	if "${CaseDD}"=="no_case" poisson AntalProv i.agegroup##c.date_spl*##c.Intervention i.Cat_num i.agegroup##i.Gender i.weekday if pop!=0, irr exposure(pop) vce(robust) /*vce(cluster NewClust)*/
	if "${CaseDD}"=="case" poisson AntalProv i.agegroup##c.date_spl*##c.Intervention i.Cat_num i.agegroup##i.Gender PosSpline* i.weekday if pop!=0, irr exposure(pop) vce(robust) /*vce(cluster NewClust)*/

	test c.Intervention /// 
	c.Intervention#2.agegroup c.Intervention#3.agegroup c.Intervention#4.agegroup c.Intervention#5.agegroup ///
	c.Intervention#c.date_spl1  ///
	c.Intervention#c.date_spl2 ///
	c.Intervention#2.agegroup#c.date_spl1 c.Intervention#3.agegroup#c.date_spl1 c.Intervention#4.agegroup#c.date_spl1 c.Intervention#5.agegroup#c.date_spl1  ///
	c.Intervention#2.agegroup#c.date_spl2 c.Intervention#3.agegroup#c.date_spl2 c.Intervention#4.agegroup#c.date_spl2 c.Intervention#5.agegroup#c.date_spl2
	
	local p: di %9.3f `=r(p)'
	putdocx paragraph
	putdocx text ("The omnibus p-value for the intervention effect is `p'")

	use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Temporary_file2.dta",clear
	gen IRR=.
	gen LCI=.
	gen HCI=.

	gen pval=.
	
	forv spl=1/3{
		replace PosSpline`spl'=0
		replace PatSpline`spl'=0
	}
	replace weekday=3
	gen pop_tmp=pop
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
		local dspl1=date_spl1[`i']
		local dspl2=date_spl2[`i']
	
		lincom c.Intervention+ /// main effect
		c.Intervention#`agegroup'.agegroup+ ///
		c.Intervention#c.date_spl1*`dspl1'+ ///
		c.Intervention#c.date_spl2*`dspl2'+ ///
		c.Intervention#`agegroup'.agegroup#c.date_spl1*`dspl1'+ ///
		c.Intervention#`agegroup'.agegroup#c.date_spl2*`dspl2',eform
		
		replace IRR=`=r(estimate)'  in `i'
		replace LCI=`=r(lb)' in `i' 
		replace HCI=`=r(ub)' in `i'
	}

		local titles `""Intervention, ages 5-14" "Intervention, ages 15-29" "Intervention, ages 30-49" "Intervention, ages 50-69" "Intervention, ages 70+""'
		format date %tdDDMonCCYY
		merge 1:1 Cat agegroup Gender date using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Fig4_tmp.dta",nogenerate
				
		export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_${model}${CaseDD}.xlsx",firstrow(variables) replace
		replace pop=pop_tmp
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\tmp.dta",replace
		keep if Intervention==1
		predict NoTests_intervention,n
		replace Intervention=0
		predict NoTests_no_intervention,n
		export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ATT_${model}.xlsx",firstrow(variables) replace

		drop NoTests*

		forv i=1/5{
			gettoken tok titles:titles
			twoway (rarea LCI HCI date if agegroup==`i',sort color(gs10)) /// 
			(line IRR date if agegroup==`i',sort lcolor(black)), saving("Graph`i'`j'",replace) ///
			graphregion(color(white)) legend(off) ytitle("Incidence rate ratio") ylabel(0.5 1 2 5 10 15)  title("`tok'") xlabel(,angle(90)) xtitle("Date") yscale(log) ylabel(,angle(0)) yline(1,lcolor(red))
		}
		graph combine "Graph1" "Graph2" "Graph3" "Graph4" "Graph5",xcommon ycommon graphregion(color(white)) iscale(*0.7)
		
		graph export "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\GraphGottsunda.png",width(2000) replace
		putdocx paragraph
		putdocx image "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\GraphGottsunda.png"
		
		use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\tmp.dta",clear
		collapse (sum) AntalProv pop Antalpositivaprov (first) Antalpatienter,by(Cat date_spl* Intervention Cat agegroup date weekday)
		export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata.xlsx",firstrow(variables) replace
	restore
}

//calculate predicted number of tests "won" by intervention
if "$model"=="cases"{
	import excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\ATT_${model}.xlsx",firstrow clear
	gen ATT=(NoTests_intervention-NoTests_no_intervention)
	egen Sum_ATT=sum(ATT)
	sum Sum_ATT
	putdocx paragraph
	putdocx text ("The ATT estimate is `=r(mean)'") 
}

//7-day moving average plots
clear
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata_ma7.dta",replace emptyok
import excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata.xlsx",firstrow clear
gen AntalPer100000=(AntalProv/pop)*100000
encode Cat,gen(Cat_num)
forv var=1/2{
	forv v2=1/5{
		preserve
		keep if agegroup==`v2' & Cat_num==`var'
		sort date
		tsset date
		egen AntalProv100000_ma7=filter(AntalPer100000),coef(1 1 1 1 1 1 1) lags(-3/3) normalise
		keep if date>=date("20200714","YMD") & date<=date("20210110","YMD")
		append using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata_ma7.dta"
		save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata_ma7.dta",replace
		restore
	}
}
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata_ma7.dta",clear
export excel "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\YorgoFig4_rawdata_ma7.xlsx",firstrow(variables) replace
********************************
