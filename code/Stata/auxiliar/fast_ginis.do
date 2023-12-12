

*settings 
clear all 

global data "data/surveys"


foreach c in "URY" "COL" "MEX" {	
	forvalues y = 2010 / 2019 {
		cap confirm file "$data/`c'/output/`c'_`y'.dta"
		if _rc == 0 {
			qui use "$data/`c'/output/`c'_`y'.dta", clear
			qui fastgini net_wth [fw = weight]
			scalar gini_`c'_`y' = r(gini)
		}
		else {
			display "There is no survey for `c'-`y'"
		}		
	}	
}

scalar list
