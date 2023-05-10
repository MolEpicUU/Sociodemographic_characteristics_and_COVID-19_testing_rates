These are the files used for the analysis of the paper "Sociodemographic characeristics and covid-19 testing rates:
spatio-temporal patterns and impact of test accessibility on Sweden"

(Almost) the entire analysis can be run using the "O_Run.do"-file. Even if the user wants to run one specific file,
there are global options in the "O_Run.do"-file that might need to be set. One for determining the vaccination populatation (all inhabitants? all older than 20?),
and one for determining the model to be run in the "3 Analysis.do"-file. By default, "O Run.do" runs all of the models.

The results are stored in Word documents (one document for each model). This is done by Statas "putdocx"-function.

"R_plots2.R" generates the correlation plots (from files created in "DescriptiveStatistics.do"). It needs to be run separately.
"CNI_postal_codes.xlsx" contains info about CNI for each postal code. 

"Preprocessing.do", "Hospitalizations.do", "CNI.do", "Agegroup Populations.do", "2 Vaccine.do" and "1 Cleaning 2021130.do" preprocesses and merges datasets for analysis.
More detailed information can be found in the header of each code. "DescriptiveStatistics_alt.do" creates most of the graphs and descriptive tables. 
"3 Analysis.do" runs the main models, generates the marginal effects and TRR plots and runs the difference-in-difference analysis.