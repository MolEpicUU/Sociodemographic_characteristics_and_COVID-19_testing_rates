//This file generates p-values for each of the sub-plots in the TRR graphs
cap postclose myfile
postfile myfile area gender agegroup pval estim lb ub using "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\pvalues${model}CNI.dta",replace

if ("$model"=="distance_cases" | "$model"=="distance_hospitalizations"){
	local ticker=0
	local add ""
	local var "${outcome}"
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
	local var "${outcome}"
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
