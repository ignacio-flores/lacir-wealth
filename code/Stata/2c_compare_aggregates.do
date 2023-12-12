*settings 
clear all
global data "data/aggregates"
global figures "figures/aggregates"
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  

//find programs folder 
sysdir set PERSONAL "code/Stata/ado_files/snacompare_wealth_ado/." 

*report step
display as text "{hline 55}"
di as result "Comparing micro-macro aggregates"
display as text "{hline 55}"
	
//call program	
snacompare_wealth using ///
	"${data}/own_estim/agg_wealth_latam.dta", ///
	svypath("${path_surveys}") weight(weight) ///
	time(2007 2020) edad(0) ///
	area(CHL MEX COL URY) show /* GRAPHEXTRAP esp */ ///
	exportexcel("results/snacompare/snacompare_wealth.xlsx") ///
	auxiliary("${path_auxfile}/aux_snacompare.do") 	



