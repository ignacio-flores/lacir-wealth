
*settings 
clear 
global data "data/surveys"

qui import delimited "$data/MEX/input/MEX_2019_js.csv", ///
	delimiter(comma) varnames(1) clear 	
	
// General variables-------------------------------------------------------------
 
qui gen  weight = fac_hog	
qui gen id_hou  = folio 

// Main variables---------------------------------------------------------------
qui gen ton_lia 	= -tot_lia
qui gen tot_ass		= fin_ass + nfi_ass 
qui egen checker 	= rowtotal(fin_ass nfi_ass ton_lia) 
qui gen net_wth		= tot_ass - tot_lia

// check net worth is equal to riq_net from survey
foreach v in net_wth riq_net checker {
	di as result "`v' gini: " _continue 
	qui sum `v'
	local tot_`v' = r(sum)
	fastgini `v' [w=weight]
	sgini `v' [w=weight]
	ineqdecgini `v' [w=weight]
}
local aux = `tot_net_wth' - `tot_riq_net'
assert abs(`aux') < 100 

local aux2 = (`tot_net_wth' - `tot_checker') / `tot_net_wth' * 100
di as result "tot_net_wth: " `tot_net_wth' 
di as result "tot_checker: " `tot_checker' 
	
global aux_part " "preliminary" " 
qui do "code/Stata/auxiliar/aux_general.do"	
	
qui keep weight id_hou  fin_ass nfi_ass tot_lia ton_lia tot_ass net_wth 

 
	qui replace ton_lia = 0 if missing(ton_lia)
	qui label var ton_lia "Total liabilities (negative)"
				
qui save "$data/MEX/output/MEX_2019.dta", replace
	
