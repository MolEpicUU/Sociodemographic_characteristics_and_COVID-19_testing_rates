//For Reviewer-response: are there significant interactions between CNI and county/city?
set matsize 10000
use "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\MainData.dta",clear
estimates use "C:\Users\ulfha881\PROJECTS\Tove\MyData\Estcases${outcome}"
noi test (c.CNI#1.area_75) /// two-way
(c.CNI#1.area_75#c.date_spl1) ///
(c.CNI#1.area_75#c.date_spl2) ///
(c.CNI#1.area_75#c.date_spl3) /// three-way
(c.CNI#1.area_75#c.date_spl4) ///
(c.CNI#1.area_75#2.Gender) ///
(c.CNI#1.area_75#2.agegroup) ///
(c.CNI#1.area_75#3.agegroup) ///
(c.CNI#1.area_75#4.agegroup) ///
(c.CNI#1.area_75#5.agegroup) ///
(c.CNI#1.area_75#2.agegroup#date_spl1) ///four-way
(c.CNI#1.area_75#2.agegroup#date_spl2) ///
(c.CNI#1.area_75#2.agegroup#date_spl3) ///
(c.CNI#1.area_75#2.agegroup#date_spl4) ///
(c.CNI#1.area_75#3.agegroup#date_spl1) ///
(c.CNI#1.area_75#3.agegroup#date_spl2) ///
(c.CNI#1.area_75#3.agegroup#date_spl3) ///
(c.CNI#1.area_75#3.agegroup#date_spl4) ///
(c.CNI#1.area_75#4.agegroup#date_spl1) ///
(c.CNI#1.area_75#4.agegroup#date_spl2) ///
(c.CNI#1.area_75#4.agegroup#date_spl3) ///
(c.CNI#1.area_75#4.agegroup#date_spl4) ///
(c.CNI#1.area_75#5.agegroup#date_spl1) ///
(c.CNI#1.area_75#5.agegroup#date_spl2) ///
(c.CNI#1.area_75#5.agegroup#date_spl3) ///	
(c.CNI#1.area_75#5.agegroup#date_spl4) ///	
(c.CNI#1.area_75#2.Gender#date_spl1) ///
(c.CNI#1.area_75#2.Gender#date_spl2) ///
(c.CNI#1.area_75#2.Gender#date_spl3) ///
(c.CNI#1.area_75#2.Gender#date_spl4) ///
(c.CNI#1.area_75#2.Gender#2.agegroup) (c.CNI#1.area_75#2.Gender#3.agegroup) /// 
(c.CNI#1.area_75#2.Gender#4.agegroup) (c.CNI#1.area_75#2.Gender#5.agegroup) ///
(c.CNI#1.area_75#2.Gender#2.agegroup#date_spl1) ///five-way
(c.CNI#1.area_75#2.Gender#2.agegroup#date_spl2) ///
(c.CNI#1.area_75#2.Gender#2.agegroup#date_spl3) ///
(c.CNI#1.area_75#2.Gender#2.agegroup#date_spl4) ///
(c.CNI#1.area_75#2.Gender#3.agegroup#date_spl1) ///
(c.CNI#1.area_75#2.Gender#3.agegroup#date_spl2) ///
(c.CNI#1.area_75#2.Gender#3.agegroup#date_spl3) ///
(c.CNI#1.area_75#2.Gender#3.agegroup#date_spl4) ///
(c.CNI#1.area_75#2.Gender#4.agegroup#date_spl1) ///
(c.CNI#1.area_75#2.Gender#4.agegroup#date_spl2) ///
(c.CNI#1.area_75#2.Gender#4.agegroup#date_spl3) ///
(c.CNI#1.area_75#2.Gender#4.agegroup#date_spl4) ///
(c.CNI#1.area_75#2.Gender#5.agegroup#date_spl1) ///
(c.CNI#1.area_75#2.Gender#5.agegroup#date_spl2) ///
(c.CNI#1.area_75#2.Gender#5.agegroup#date_spl3) ///
(c.CNI#1.area_75#2.Gender#5.agegroup#date_spl4)	
