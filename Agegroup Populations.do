//Calculates information about the number of individuals within specific age ranges for each postal code
//(to be merged with main file)
cd "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\SCB\leverans20210621"
import excel "UU_Postnummer202103.xlsx",firstrow clear cellrange(A8:BO10399)
drop in 1
destring *,replace

//the combinations of gender and the five age categories
egen pop_5_14_male=rowtotal(C-D)
egen pop_15_29_male=rowtotal(E-G)
egen pop_30_49_male=rowtotal(H-M)
egen pop_50_69_male=rowtotal(L-O)
egen pop_70_105_male=rowtotal(P-V)

egen pop_5_14_female=rowtotal(Y-Z)
egen pop_15_29_female=rowtotal(AA-AC)
egen pop_30_49_female=rowtotal(AD-AG)
egen pop_50_69_female=rowtotal(AH-AK)
egen pop_70_105_female=rowtotal(AL-AR)
***********************

****other useful age categorizations*****
egen pop_25_64=rowtotal(G-N AC-AJ)
egen pop_15_64=rowtotal(E-N AA-AJ)
egen pop_65_plus=rowtotal(O-V AK-AR)
egen pop_20_105=rowtotal(F-V AB-AR)
egen pop_15_105=rowtotal(E-V AA-AR)
*****************************

rename A postnummer
keep postnummer pop*
tostring postnummer,replace
replace postnummer="74020" if postnummer=="75578" | postnummer=="75577" | postnummer=="75576"
collapse (sum) pop*,by(postnummer)
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\AgegroupPopulations.dta",replace
