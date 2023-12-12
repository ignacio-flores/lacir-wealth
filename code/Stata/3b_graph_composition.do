clear all

*general settings  
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  

// get list 
local xcel "${path_results}/ineqstats_results.xlsx"
qui import excel `xcel', sheet("Summary") ///
	clear firstrow 
qui keep if !missing(average)
qui collapse (max) year, by(country)
qui levelsof country, local(ctries) clean 
foreach c in `ctries' {
	qui levelsof year if country == "`c'", local(`c'y) clean 
}

//loop over them 
foreach c in `ctries' {
	qui import excel `xcel', sheet("`c'``c'y'") clear firstrow
	keep country year average p bckt_avg ch_*
	qui replace p = p*10^2
	qui rename ch_* * 
	
	qui gen n = _n
	tsset n
	foreach prut in fin_ass nfi_ass non_ass ton_lia  {
		qui egen ma_`prut' = filter(`prut'), ///
			coef(1 1 1 1 1 1 1 1 1) lags(-4/4) normalise
	}
	
	qui genstack ma_fin_ass ma_nfi_ass ma_non_ass ma_ton_lia, gen(f_)
	
	qui lab var f_ma_fin_ass "financial"
	qui lab var f_ma_nfi_ass "non-financial" 
	qui lab var f_ma_ton_lia "debt"
	qui lab var f_ma_non_ass "no assets/debt"
	
	graph twoway  ///
		(area f_ma_ton_lia p, lwidth(none)) ///
		(area f_ma_non_ass p, lwidth(none)) ///
		(area f_ma_nfi_ass p, lwidth(none)) ///
		(area f_ma_fin_ass p, lwidth(none))  ///
		/*if f_ma_nfi_ass <= 100 & f_ma_fin_ass <= 100*/, ///
		title("Main asset category by percentile `c'-``c'y'") ///
		ytit("Share of population") xtit("percentile") ///
		ylab(, angle(horizontal)) $graph_scheme ///
		legend(subtitle("Category") row(2))	
	cap graph export ///
		"figures/surveys/ineqstats/countries/comp`c'.pdf", ///
		replace	
}
