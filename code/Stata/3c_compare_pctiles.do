clear all

*general settings  
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  
global figures "figures/surveys/ineqstats"

// get list of countries with last year 
local xcel "${path_results}/ineqstats_results.xlsx"
qui import excel `xcel', sheet("Summary") ///
	clear firstrow 
qui keep if !missing(average)
qui collapse (max) year, by(country)
qui levelsof country, local(ctries) clean 
foreach c in `ctries' {
	qui levelsof year if country == "`c'", local(`c'y) clean 
}

//download wid data 
local widvars xlcusp xlcusx inyixx 
qui wid, indicators(`widvars') ages(999) pop(i) areas(CO CL MX UY) clear
qui keep country variable year value 

//reshape and rename 
qui rename value v
qui reshape wide v, i(country year) j(variable) string 
qui replace country = "COL" if country == "CO"
qui replace country = "CHL" if country == "CL"
qui replace country = "URY" if country == "UY"
qui replace country = "MEX" if country == "MX"
qui rename *999i *

//collect price index and exchange rate for a given year 
foreach c in `ctries' {
	qui sum vinyixx if country == "`c'" & year == ``c'y'
	local `c'pi = r(mean) 
	foreach d in x p {
		qui sum vxlcus`d' if year == 2021 & country == "`c'", meanonly 
			local `c'x`d'2021 = r(mean)
	}
}

//loop over distributional results 
tempfile tf_micro 
local iter = 0
foreach c in `ctries' {
	
	//alt caller 
	local c2 = strlower("`c'")
	
	//open file 
	qui import excel `xcel', sheet("`c'``c'y'") clear firstrow
	qui keep country average p bckt_avg 
	foreach v in country average {
		qui replace `v' = `v'[1]
	}
	
	//get real 
	qui gen r_ba = bckt_avg / ``c'pi'
	
	//transform to USD and prepare graph 
	di as result "CPI `c'pi (``c'y'): ``c'pi'"
	foreach d in x p {
		di as text "xrate vxlcus`d' (2021): ``c'x`d'2021'"
		qui gen r_usd`d' = (r_ba / ``c'x`d'2021') / 1000
		
		//prepare graph 
		local gf_`d' `gf_`d'' (connect r_usd`d' p if country == "`c'", ///
			color(${c_`c2'}) msize(vsmall))
	}
	
	//save 
	if `iter' != 0 {
		qui append using `tf_micro'
	}
	save `tf_micro', replace 
	local iter = 1
}

//graph 
qui sort country p 
qui replace p = round(p *100)
graph twoway `gf_x', ytit("Average net wealth, 2021 USD MER (thds.)") ///
	xtit("Percentile") ///
	ylabel(-200(200)1600, ${ylab_opts}) xlabel(0(10)100, ${xlab_opts}) ///
	legend(order(1 "CHL 2017" 2 "COL 2018" 3 "MEX 2019" 4 "URY 2013") ///
	position(0) bplacement() col(1) symxsize(2pt) region(lcolor(none))) ///
	$graph_scheme 
qui graph export "$figures/nworth_by_percentile_MER.pdf", replace	
	
graph twoway `gf_p', ytit("Average net wealth, 2021 USD PPP (thds.)") ///
	xtit("Percentile") ///
	ylabel(-200(200)1600, ${ylab_opts}) xlabel(0(10)100, ${xlab_opts}) ///
	legend(order(1 "CHL 2017" 2 "COL 2018" 3 "MEX 2019" 4 "URY 2013") ///
	position(0) bplacement() col(1) symxsize(2pt) region(lcolor(none))) ///
	$graph_scheme 
qui graph export "$figures/nworth_by_percentile_PPP.pdf", replace			
	
	
