clear

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

// get list of paths
global data "data/surveys"
 
* Empty file to save Gini indexes:
clear
set obs 1
gen country = ""
gen year = .
gen mean = .
gen n_obs = .
gen iqr = .
gen sd = .
gen median = .

tempfile mean
save `mean', replace

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
	
			qui use "$data/`c'/output/`c'_`y'.dta", clear
		capture gen country = "`c'"
		capture gen year = `y'
		
		di "`c' - `y'"
		
		global var net_wth
		global weight weight
		
		gen share_zero = ($var == 0) if !missing($var)
		gen share_neg = ($var < 0) if !missing($var)
		
		if "`c'" == "COL"{
		    * Remove individuals with zero total assets as they are not part of 
			* the survey design in Colombia.
		    drop if tot_ass == 0
		}
		
		collapse (median) median = $var (mean) mean = $var share_zero share_neg (count) n_obs = $var (iqr) iqr = $var (sd) sd = $var [w = $weight], by(country year)
		
		append using `mean'
		save `mean', replace
		
		restore
		*/
		}
}		

use `mean'
gen cvar = sd/mean
sort country year
order country year n_obs mean median share_zero share_neg iqr cvar
drop sd
drop if year == .

export excel using ///
	"figures/surveys/survey summary/wealth_surveys_summary", ///
	firstrow(variables) replace

gen mean_to_median = mean/median
replace mean = asinh(mean)
replace median = asinh(median)
replace iqr = asinh(iqr)
replace n_obs = n_obs/1000

cap erase "figures/surveys/survey summary/g1.gph"
cap erase "figures/surveys/survey summary/g2.gph"
cap erase "figures/surveys/survey summary/g3.gph"
cap erase "figures/surveys/survey summary/g4.gph"
cap erase "figures/surveys/survey summary/g5.gph"
cap erase "figures/surveys/survey summary/g6.gph"

* Skip value missing as Colombia is not in this graph:
 replace share_zero = . if country == "COL"
tw  (connect share_zero year if country == "CHL") ///
	(connect share_zero year if country == "COL") ///
	(connect share_zero year if country == "MEX") ///
	(connect share_zero year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico") label(4 "Uruguay") ///
	pos(7) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Share with zero net assets") ylabel(0(.1).4,angle(0) ///
	format(%12.1f)) saving("figures/surveys/survey summary/g5.gph")
	

tw  (connect share_neg year if country == "CHL") ///
	(connect share_neg year if country == "COL") ///
	(connect share_neg year if country == "MEX") ///
	(connect share_neg year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico")label(4 "Uruguay") ///
	pos(7) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Share with negative net assets") ///
	ylabel(0(.1).4,angle(0) format(%12.1f)) ///
	saving("figures/surveys/survey summary/g6.gph")
	
tw  (connect mean_to_median year if country == "CHL") ///
	(connect mean_to_median year if country == "COL") ///
	(connect mean_to_median year if country == "MEX") ///
	(connect mean_to_median year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico") label(4 "Uruguay") ///
	pos(7) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Mean-to-median ratio") ylabel(0(1)5, ///
	format(%12.0f) angle(0)) ///
	saving("figures/surveys/survey summary/g1.gph", replace)
	
tw  (connect median year if country == "CHL") ///
	(connect median year if country == "COL") ///
	(connect median year if country == "MEX") ///
	(connect median year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico") label(4 "Uruguay") ///
	pos(7) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Median net wealth (IHS)") ylabel(0(5)20,angle(0)) ///
	saving("figures/surveys/survey summary/g2.gph", replace)
	

tw  (connect iqr year if country == "CHL") ///
	(connect iqr year if country == "COL") ///
	(connect iqr year if country == "MEX") ///
	(connect iqr year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico") label(4 "Uruguay") ///
	pos(7) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Inter-quartile range (IHS)") ylabel(0(5)20,angle(0)) ///
	saving("figures/surveys/survey summary/g3.gph", replace)


tw  (connect cvar year if country == "CHL") ///
	(connect cvar year if country == "COL") ///
	(connect cvar year if country == "MEX") ///
	(connect cvar year if country == "URY"), ///
	legend(label(1 "Chile") label(2 "Colombia") ///
	label(3 "Mexico") label(4 "Uruguay") ///
	pos(11) row(1)) xlabel(2007(2)2019, angle(0)) xtitle("") ///
	ytitle("Coefficient of variation") ///
	ylabel(0(5)20,angle(0)) ///
	saving("figures/surveys/survey summary/g4.gph", replace)	
	
grc1leg ///
	"figures/surveys/survey summary/g1.gph" ///
	"figures/surveys/survey summary/g4.gph" ///
	"figures/surveys/survey summary/g5.gph" ///
	"figures/surveys/survey summary/g6.gph", ///
	legendfrom("figures/surveys/survey summary/g1.gph") ///
	row(2) pos(6) ring(1)

*graph display, xsize(6)
graph export "figures/surveys/survey summary/wealth_surveys_summary.pdf", ///
	replace
	
cap erase "figures/surveys/survey summary/g1.gph"
cap erase "figures/surveys/survey summary/g2.gph"
cap erase "figures/surveys/survey summary/g3.gph"
cap erase "figures/surveys/survey summary/g4.gph"
cap erase "figures/surveys/survey summary/g5.gph"
cap erase "figures/surveys/survey summary/g6.gph"	


