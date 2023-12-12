clear all

*general settings  
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  
sysdir set PERSONAL "${path_adofile}" 	

//call program	
ineqstats_wealth_old summarize, svypath(${path_surveys}) edad(0) type("") ///
	time(2007 2020) area(${svy_countries}) ext("") ///
	export("${path_results}/ineqstats_results.xlsx") ///
	weight(weight) dec(${wealth_decomp}) smoothtop 
