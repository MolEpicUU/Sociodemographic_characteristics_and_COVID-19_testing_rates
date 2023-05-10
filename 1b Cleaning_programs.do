//FILES FROM SCB
**************************************************************************
//extracting postal code populations and % women per postal code for merging with main file
import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\SCB\leverans20210621\UU_Postnummer202103.xlsx", sheet("1b") cellrange(A9:J10416) firstrow clear
rename PostNr postnummer
keep postnummer G J
rename (G J) (Kvinnor2 Totalt2) 
isid postnummer
replace postnummer="74020" if postnummer=="75578" | postnummer=="75577" | postnummer=="75576" //one postal code split into three during study period
egen K=sum(Kvinnor2),by(postnummer)
egen t=sum(Totalt2),by(postnummer)
replace Kvinnor2=K
replace Totalt2=t
drop K t
duplicates drop
gen andel_kvinnor2=Kvinnor2/Totalt2
rename Totalt2 pop2
keep postnummer andel_kvinnor2 pop2
destring postnummer, force replace
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Gender_Adult_pop.dta",replace

//Extracting mean age per postal code (from earlier Statistics Sweden-file)
import excel "\\argos.rudbeck.uu.se\MyGroups$\Gold\CRUSH_Covid\SCB\PostnrStatistik_Alla tabeller.xlsx", sheet("T9") cellrange(A9) clear firstrow
keep if Kön=="Totalt"
rename Postnummer postnummer
rename Medelålder medelålder
keep postnummer medelålder
destring postnummer, force replace
save "C:\Users\ulfha881\PROJECTS\Tove\CRUSH\MyData\Alder.dta",replace
