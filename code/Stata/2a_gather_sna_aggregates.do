*settings 
clear 
global data "data/aggregates"
global figures "figures/aggregates"
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  
tempfile chl ury grouped 
tempvar country_aux 

// import Chilean nonfinancial 
local vars_chl v_housing_nni v_agri_mv_nni v_oth_real_A_nni
qui use year `vars_chl' if inrange(year, 2009, 2020) ///
	using "$data/FG2021/agg_data_floresgutierrez2021_nni.dta", clear
qui sum v_oth_real_A_nni_efh, meanonly 
qui replace v_oth_real_A_nni_efh = r(mean) if missing(v_oth_real_A_nni_efh)	
qui gen country = "CHL" 
qui egen nfi = rowtotal(`vars_chl')
qui keep country year nfi
qui sort country year 
qui save `chl'
	
// import Uruguayan estimates
qui use "$data/aggregates_wid/Countries/Uruguay/ury_nat_weatlh.dta", clear
qui gen country = "URY"
qui gen naw_b 	= (nfass_hh_ni + nass_hh_ni + nfass_cor_ni + nass_cor_ni + pen_hh_ni) / 100
qui gen npu 	= net_gov_worth
qui gen nwt_b	= naw_b - npu 
qui gen nfa 	= iip_ni
qui sort year 
qui keep year country naw_b npu nwt_b nfa
qui keep if inrange(year, 2009, 2016)	
qui save `ury'	

// import summary: MEX
tempfile mex
import excel ///
	"$data/aggregates_wid/Countries/BB_graphs Comparison.xlsx", ///
	sheet("Comparison") cellrange(B11:QA27) clear case(lower)
	qui keep B PV PW PZ QA
	qui rename (B PV PZ QA) (year naw nco npu)
	qui gen country = "MEX"
	qui sort country year 
	qui save `mex' 

// import financial assets: COL, BRA, MEX and CHL
import excel ///
	"$data/aggregates_wid/Countries/BB_graphs Comparison.xlsx", ///
	sheet("Private wealth") cellrange(A2:E26) firstrow clear case(lower)
qui rename (colombia brazil mexico chile) (fin1 fin2 fin3 fin4)
qui reshape long fin, i(year) j(`country_aux')
qui drop if missing(fin)
qui gen     country = "COL" if `country_aux' == 1
qui replace country = "BRA" if `country_aux' == 2
qui replace country = "MEX" if `country_aux' == 3
qui replace country = "CHL" if `country_aux' == 4	

qui sort country year
qui save `grouped' 

// import net foreigns assets: COL, BRA, MEX and CHL
import excel "$data/aggregates_wid/Countries/BB_graphs Comparison.xlsx", ///
	sheet("National wealth") cellrange(M2:Q26) firstrow clear case(lower)
qui rename (colombia brazil mexico chile) (nfa1 nfa2 nfa3 nfa4)
qui reshape long nfa, i(year) j(`country_aux')
qui drop if missing(nfa)

qui gen     country = "COL" if `country_aux' == 1
qui replace country = "BRA" if `country_aux' == 2
qui replace country = "MEX" if `country_aux' == 3
qui replace country = "CHL" if `country_aux' == 4
	
qui sort country year	
qui merge country year using `grouped'
qui drop _merge 
qui order country year 
qui sort country year
qui save `grouped', replace 


// import non financial assets: COL, BRA, MEX and CHL
import excel "$data/aggregates_wid/Countries/BB_graphs Comparison.xlsx", ///
	sheet("Private wealth") cellrange(G2:K26) firstrow clear case(lower)
qui rename (colombia brazil mexico chile) (nfi1 nfi2 nfi3 nfi4)
qui reshape long nfi, i(year) j(`country_aux')
qui drop if missing(nfi)

qui gen     country = "COL" if `country_aux' == 1
qui replace country = "BRA" if `country_aux' == 2
qui replace country = "MEX" if `country_aux' == 3
qui replace country = "CHL" if `country_aux' == 4

qui sort country year
qui merge country year using `grouped'
qui sort country year
qui drop _merge 
qui save `grouped', replace 
	
// import liabilities: COL, BRA, MEX and CHL
import excel "$data/aggregates_wid/Countries/BB_graphs Comparison.xlsx", ///
	sheet("Private wealth") cellrange(M2:Q26) firstrow clear case(lower)
qui rename (colombia brazil mexico chile) (lia1 lia2 lia3 lia4)
qui reshape long lia, i(year) j(`country_aux')
qui drop if missing(lia)

qui gen country     = "COL" if `country_aux' == 1
qui replace country = "BRA" if `country_aux' == 2
qui replace country = "MEX" if `country_aux' == 3
qui replace country = "CHL" if `country_aux' == 4
	
qui sort country year	
qui merge country year using `grouped'
qui drop _merge 
qui order country year 
qui save `grouped', replace 
	
// merge all and compute private wealth/
qui sort country year 
qui merge country year using `chl', update
qui drop _merge
qui sort country year 
qui merge country year using `mex', update 
qui drop _merge
qui gen nwt 	= nfi + fin - lia
qui gen ali 	= fin - lia
qui gen naw_b 	= naw + nco
qui gen nwt_b 	= nwt + nco
qui append using `ury'
qui gen dom  	= naw   - nfa
qui gen dom_b  	= naw_b - nfa
qui sort country year 
qui save `grouped', replace 

//download nni from wil 
qui wid, indicators(mnninc inyixx) areas(BR MX UY CL CO) years(1996/2020) clear 
kountry country, from(iso2c) to(iso3c) 
qui replace country = _ISO3C_
qui keep country year variable value 
qui sort country variable year
qui reshape wide value, i(country year) j(variable) string 
qui rename value*999i *
qui rename (mnninc inyixx) (nni pri)
qui replace nni = nni * pri 
qui drop pri  
qui merge country year using `grouped'
qui keep if inlist(_merge, 2, 3)
qui drop _merge 

qui save "$data/own_estim/agg_wealth_latam.dta", replace
