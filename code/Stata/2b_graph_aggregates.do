*settings 
clear 
global data "data/aggregates"
global figures "figures/aggregates"
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  

//download wid data 
local widvars xlcusp xlcusx /// 
	xlceux xlcyux inyixx mnninc mgdpro ///
	ahweal apweal mpweal mhweal npopul npopem
qui wid, indicators(`widvars') ages(999 992) pop(i) areas(BR CL MX UY CO) clear
qui keep country variable year value 

//reshape and rename 
qui rename value v
qui reshape wide v, i(country year) j(variable) string 
qui replace country = "BRA" if country == "BR"
qui replace country = "CHL" if country == "CL"
qui replace country = "URY" if country == "UY"
qui replace country = "MEX" if country == "MX"
qui replace country = "COL" if country == "CO"
qui rename *999i *

//collect recent exchange rates for later 
local clist BRA CHL URY MEX COL

foreach c in `clist' {
	foreach d in x p {
		qui sum vxlcus`d' if year == 2021 & country == "`c'", meanonly 
			local `c'_x`d'2021 = r(mean)
	}
}

//save in memory 
tempfile tfwid 
qui save `tfwid'

//open main data and merge 
qui use "$data/own_estim/agg_wealth_latam.dta", clear 
cap drop __*
qui merge 1:1 country year using `tfwid', keep(3) nogen 


//compare with wid values
qui gen wid_priv = vmpweal / vmnninc 
qui gen wid_hhld = vmhweal / vmnninc 

//get real values in usd 
foreach d in x p {
	qui gen nwt_us`d' = nwt * vmnninc
	foreach c in `clist' {
		qui replace nwt_us`d' = nwt_us`d' / ``c'_x`d'2021' if ///
			country == "`c'"
	}
}

//get percapita (our estimates)
qui gen nwt_usx_pc 		= nwt_usx   * 10^-3 / vnpopul
qui gen nwt_usp_pc 		= nwt_usp   * 10^-3 / vnpopul

//percapita (widestimates)
qui gen wid_pweal_usdx = . 
foreach c in `clist' {
	qui replace wid_pweal_usdx = (vapweal / ``c'_xx2021') * 10^-3 ///
		if country == "`c'"
}

* graph net worth 
foreach c in BRA CHL MEX URY COL {
	local c2 = strlower("`c'")
	*first graph 
	local grapher1 `grapher1' ///
		(connect nwt year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall))
	local grapher1_b `grapher1_b' ///
		(connect nwt_b year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall) msymbol(T) lp(dash))		
	*public 
	local grapher_pub `grapher_pub' ///
		(connect npu year if country == "`c'", ///
		color(${c_`c2'}) msymbol(X))
	*national wealth graph 
	local grapher_naw `grapher_naw' ///
		(connect naw year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall))
	local grapher_naw_b `grapher_naw_b' ///
		(connect naw_b year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall) msymbol(T) lp(dash))	
	*net foreign asset position
	local grapher_nfa `grapher_nfa' ///
		(connect nfa year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall) msymbol(D))
	*domestic capital
	local grapher_dom `grapher_dom' ///
		(connect dom year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall))
	local grapher_dom_b `grapher_dom_b' ///
		(connect dom_b year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall) msymbol(T) lp(dash))	
	*percapita all 	
	local grapher_pcx `grapher_pcx' ///
		(connect nwt_usx_pc year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall))
	*percapita comparison w/ wid 
	local grapher_pc_comp `grapher_pc_comp' ///
		(connect nwt_usx_pc year if country == "`c'", ///
		color(${c_`c2'}) msize(vsmall)) ///
		(line wid_pweal_usdx year if country == "`c'", ///
		lcolor(${c_`c2'}) lpattern(dash) msize(vsmall)) 
}

*wealth to income ratios (all)
twoway `grapher1' `grapher1_b' if year >= 2002  , $graph_scheme ///
	ylabel(-1(1)7, $ylab_opts) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Private wealth-to-income ratio")	///
	legend(order(1 "Brazil" 2 "Chile" 3 "Mexico" 8 "Mexico*" 9 "Uruguay*") ///
	row(1) symxsize(3pt)) ///
	aspect(.4)
qui graph export "$figures/net_worth.pdf", replace


// average wealth
twoway `grapher_pcx' `grapher_pcx_b' if year >= 2002 , $graph_scheme  ///
	ylabel(, $ylab_opts) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Percapita wealth, 2021 USD MER (thds.)")	///
	legend(order(1 "Brazil" 2 "Chile" 3 "Mexico" 8 "Mexico*" 9 "Uruguay*") ///
	row(1) symxsize(3pt)) ///
	aspect(.4)
qui graph export "$figures/avg_net_worth.pdf", replace	


// domestic capital and net foreign asset position
twoway `grapher_nfa' `grapher_dom' `grapher_dom_b'  if year >= 2002 , $graph_scheme  ///
	ylabel(-1(1)7, $ylab_opts format(%5.0f)) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Net wealth-to-income ratio")	///
	legend(order(1 "Brazil (NFA)" 2 "Chile (NFA)" 3 "Mexico (NFA)" 4 "Uruguay (NFA)" 5 "Colombia (NFA)" ///
	 8 "Mexico (K)" 13 "Mexico* (K)" 14 "Uruguay* (K)" )) ///
	aspect(.4)
qui graph export "$figures/dom_nfa_net_worth.pdf", replace


// public and national
twoway `grapher_pub' `grapher_naw' `grapher_naw_b'  if year >= 2002 , $graph_scheme  ///
	ylabel(-1(1)7, $ylab_opts format(%5.0f)) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Net wealth-to-income ratio")	///
	legend(order(3 "Mexico (pub)" 4 "Uruguay (pub)" 8 "Mexico (nat)" 13 "Mexico* (nat)" 14 "Uruguay* (nat)")) /// 
	aspect(.4)
qui graph export "$figures/pri_pub_net_worth.pdf", replace
 
twoway `grapher_pc_comp'  `grapher_pc_comp_b' if year >= 2002 , $graph_scheme  ///
	ylabel(, $ylab_opts) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Private wealth in thsd. usd xrate (pc)")	///
	legend(/*order(1 "Brazil" 2 "Chile" 3 "Mexico" 4 "Uruguay")*/ off) ///
	aspect(.4)
qui graph export "$figures/avg_net_worth_comparison.pdf", replace	

*wealth to income ratios clean cut 
twoway `grapher1' if year >= 2002, $graph_scheme ///
	ylabel(-1(1)7, $ylab_opts) xlabel(2002(2)2020, $xlab_opts) ///
	xtitle("") ytitle("Private wealth to income ratio")	///
	legend(order(1 "Brazil" 2 "Chile" 3 "Mexico" 4 "Uruguay")) ///
	aspect(.4)
qui graph export "$figures/net_worth_clean.pdf", replace


*financial assets 
foreach c in BRA MEX COL CHL {
	local c2 = strlower("`c'")
	local grapher2 `grapher2' ///
		(connect ali year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}	
twoway `grapher2', $graph_scheme ///
	ylabel(-1(1)7, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Net fin. ass (% nat. inc.)")	///
	legend(order(1 "Brazil" 2 "Mexico"  ///
	3 "Colombia" 4 "Chile")) aspect(.4)
qui graph export "$figures/net_fin_ass.pdf", replace


// Download WIL data to compare
tempfile wealth_wil 
qui wid, indicators(mpweal) clear // mhweal 
qui rename value nwt_agg
qui save `wealth_wil'

qui wid, indicators(mnninc) clear 
qui rename value inc_agg

qui merge 1:1 country year using `wealth_wil', nogen
kountry country, from(iso2c) to(iso3c) 
qui replace country = _ISO3C_

qui gen aux = 0
qui replace aux = 1 if inlist(country, "BRA", "MEX", "URY", "COL", "CHL")
qui replace aux = 1 if inlist(country, "ARG", "ECU", "PER", "SLV", "CRI", "DOM")
qui keep if aux == 1 

qui merge 1:1 country year using `wealth_wil', nogen

qui gen nwt = nwt_agg / inc_agg
qui keep if year > 1995


* countries with own estimates
foreach c in BRA MEX URY CHL {
	local c2 = strlower("`c'")
	local grapher3 `grapher3' ///
		(connect nwt year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}
twoway `grapher3', $graph_scheme 						///
	ylabel(-1(1)7, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Private wealth to income ratio")	///
	legend(/*order(1 "BRA" 2 "MEX" 3 "URY" 4 "COL" 5 "CHL")*/ off)	///
	aspect(.4)
qui graph export "$figures/net_worth_wil.pdf", replace

* rest

foreach c in ARG ECU PER SLV CRI DOM COL {
	local c2 = strlower("`c'")
	local grapher4 `grapher4' ///
		(connect nwt year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}
twoway `grapher4', $graph_scheme 						///
	ylabel(-1(1)7, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Private wealth to income ratio")	///
	legend(/*order(1 "BRA" 2 "MEX" 3 "URY" 4 "COL" 5 "CHL")*/ off)	///
	aspect(.4)
qui graph export "$figures/net_worth_wil_rest.pdf", replace

* all

foreach c in BRA MEX URY CHL ARG ECU PER SLV CRI DOM COL {
	local c2 = strlower("`c'")
	local grapher5 `grapher5' ///
		(connect nwt year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}
twoway `grapher5', $graph_scheme 						///
	ylabel(-1(1)7, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Priv. wth.-to-inc. ratio")	///
	legend(order(1 "BRA" 2 "MEX" 3 "URY" 4 "CHL" 5 "ARG" ///
	6 "ECU" 7 "PER" 8 "SLV" 9 "CRI" 10 "DOM" 11 "COL"))	///
	aspect(.4) 
qui graph export "$figures/net_worth_wil_all.pdf", replace

*legends
foreach c in BRA MEX URY CHL COL ARG ECU PER SLV CRI DOM  {
	local c2 = strlower("`c'")
	local grapher5 `grapher5' ///
		(connect nwt year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}
twoway `grapher5', $graph_scheme 						///
	ylabel(0(1)6, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Private wealth to income ratio")	///
	legend(order(1 "BRA" 2 "MEX" 3 "URY" 4 "CHL" 5 "COL" 6 "ARG" 7 "ECU" 8 "PER" 9 "SLV" 10 "CRI" 11 "DOM"))	///
	aspect(.4)
qui graph export "$figures/legend.pdf", replace

foreach c in BRA MEX URY CHL {
	local c2 = strlower("`c'")
	local grapher6 `grapher6' ///
		(connect nwt year if country == "`c'", color(${c_`c2'}) msize(vsmall))
}
twoway `grapher5', $graph_scheme 						///
	ylabel(0(1)6, ${ylab_opts}) xlabel(1996(2)2020, ${xlab_opts}) ///
	xtitle("") ytitle("Private wealth to income ratio")	///
	legend(order(1 "BRA" 2 "MEX" 3 "URY" 4 "CHL" ))	///
	aspect(.4)
qui graph export "$figures/legend_short.pdf", replace

