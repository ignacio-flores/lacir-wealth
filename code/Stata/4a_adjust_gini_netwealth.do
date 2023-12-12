*settings 
clear 
global data "data/surveys"

************************
* Set graphics
 grstyle init
 grstyle set plain, grid
 grstyle set legend 5, nobox inside
 grstyle set color cblind, select(1 2 3 4 5 7 8 9)
 grstyle set symbol O T S D Oh Th Sh Dh
 grstyle set symbolsize large
 grstyle set lpattern solid solid solid solid
 grstyle set compact
************************	

* Empty file to save Gini indexes:
clear
set obs 1
gen country = ""
gen year = .
gen gini_unadj = .
gen gini_adj = .

tempfile ginis
save `ginis', replace


* Get SNA to survey comparison:
import excel "results/snacompare/snacompare_wealth.xlsx", ///
	sheet("ratios") firstrow clear
* Save tempfile
tempfile snacompare
save `snacompare', replace
	
	
// Locals:
levelsof country, local(countries)
foreach c of local countries{

qui levelsof year if country == "`c'", local(years)

foreach y of local years{
		
		preserve
		use "$data/`c'/output/`c'_`y'.dta", clear
		capture gen country = "`c'"
		capture gen year = `y'
		
		di "`c' - `y'"
		
		global var net_wth
		global weight weight
		
		qui ineqdec0 $var [w = $weight]
		di "Default Gini: `r(gini)'"
		scalar gini_survey = r(gini)
		qui do "code/Stata/auxiliar/Example Gini with negative values.do"
		qui sum adj_gini
		di "Adjusted Gini `r(mean)'"
		scalar gini_adj = r(mean)

		clear
		set obs 1
		gen country = "`c'"
		gen year = `y'
		
		gen gini_unadj = gini_survey
		gen gini_adj = gini_adj
		
		append using `ginis'
		save `ginis', replace
		
		restore
		}
}		

//graph 
clear
use `ginis', clear
tw  (connect gini* year if country == "CHL", mcolor(cranberry cranberry) ///
	msymbol(O Oh) lcolor(cranberry cranberry) lpattern(solid shortdash)) ///
	(connect gini* year if country == "COL", mcolor(gold gold) msymbol(D Dh) ///
	lcolor(gold gold) lpattern(solid shortdash)) ///
	(scatter gini* year if country == "MEX", msymbol(T Th) ///
	mcolor(dkgreen dkgreen)) ///
	(scatter gini* year if country == "URY", msymbol(S Sh) ///
	mcolor(ebblue ebblue)), legend(label(1 "CHL") label(3 "COL")  ///
	label(5 "MEX") label(7 "URY") label(2 "CHL") label(4 "COL") ///
	label(6 "MEX") label(8 "URY") ///
	order(- "Gini (default):" 1 3 5 7 - "Adjusted Gini:" 2 4 6 8) ///
	ring(1) pos(6) row(2)) xlabel(2007(2)2019) xtitle("") ///
	ylabel(0.5(.1)1, angle(0) format(%12.1f)) ytitle("Gini coefficient")	
graph export adjustedgini_netwealth.pdf, replace
export excel using "figures/surveys/adjusted gini/adjustedgini_netwealth", ///
	firstrow(variables) replace
grstyle set symbol O O O O O 

tw  (connect gini_unadj year if country == "CHL", ///
	msize(normal) mcolor(cranberry cranberry) ///
	lcolor(cranberry cranberry) lpattern(solid shortdash)) ///
	(connect gini_unadj year if country == "COL", ///
	msize(normal) mcolor(gold gold) lcolor(gold gold) ///
	lpattern(solid shortdash)) ///
	(scatter gini_unadj year if country == "MEX", msize(normal) ///
	mcolor(dkgreen dkgreen)) ///
	(scatter gini_unadj year if country == "URY", msize(normal) ///
	mcolor(ebblue ebblue)), legend(off) xlabel(2006(2)2020) xtitle("") ///
	yline(0, lpattern(dash) lcolor(black)) ylabel(-.1(.1)1, angle(0)) ///
	ytitle("Gini coefficient") saving(wealth_gini.gph, replace)
graph export "figures/surveys/adjusted gini/wealth_gini.pdf", replace
