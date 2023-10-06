******Importing information about Care Need Index (and associated variables) per postal code
cd "C:\Users\ulfha881\PROJECTS\Tove\CRUSH"
import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\CNI\CNI efter postnr_2020.xlsx",firstrow clear
import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\CNI\CNI efter postnr_2020.xlsx",firstrow clear cellrange(A5:O10382)
//75460 finns inte här. Därav 350.
keep A-H K
drop in 1
rename (A B C D E F G H K) (postnummer Below5 NonEU Above65_livingalone SingleParentWithChildBelow18 PersonsAbove0MovingIntoArea Unemployed LowEducation2564 CNI)
replace postnummer="74020" if postnummer=="75578" | postnummer=="75577" | postnummer=="75576"
destring *,replace
tostring postnummer,replace
//the "collapse" is due to one postal code being split into three during 2021.
//therefore, individuals for the three areas are added (while the average of CNI is taken)
collapse (mean) CNI (sum) Below5 NonEU Above65_livingalone SingleParentWithChildBelow18 PersonsAbove0MovingIntoArea LowEducation2564 Unemployed,by(postnummer)
save "MyData/CNI.dta",replace
keep postnummer CNI
*******************************************
