clear all 

//general settings
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  

//Options 
global ineqvars " "t10_sh" "m40_sh" "b50_sh" "gini" "t1_sh" " 
global groups " "t10" "m40" "b50" "t1" "tot" "

//import inflation data
quietly import excel using ${infl_dta}, ///
	firstrow sheet("inflation-xrates") clear 
quietly keep country year cpi_20	
tempfile tf_inflation
quietly save `tf_inflation'

//import summary and save for later 	
qui import excel "${path_results}/ineqstats_results.xlsx", ///
	sheet("Summary") firstrow clear
tempfile tf_1
quietly save `tf_1'

//import summary of composition 	
qui import excel "${path_results}/ineqstats_results.xlsx", ///
	sheet("Composition") firstrow clear
quietly merge 1:1 country year using `tf_1', nogen	keep(3)

//Placebo 
quietly gen tot_sh = 1

*get cpi 
quietly merge 1:1 country year using `tf_inflation', keep(3) nogen 
quietly gen real_avg = average / cpi_2020 

//define variable lists by group 
quietly ds 
local all_vars "`r(varlist)'"
foreach group in $groups {
	foreach var in `all_vars' {
		if "`var'" != "`group'_sh" & strpos("`var'", "`group'_") {
			local varlist_`group' "`varlist_`group'' `var'" 
		}
	}
	*get average wealth of each group 
	if strpos("`group'", "b50") local popsh = .5
	if strpos("`group'", "m40") local popsh = .4
	if strpos("`group'", "t10") local popsh = .1
	if "`group'" == "t1" local popsh = .01
	if !inlist("`group'", "tot") {
		di as result "`group'"
		quietly gen `group'_avg = (`group'_sh / `popsh') * real_avg
		quietly replace `group'_avg = `group'_avg 
		qui label var `group'_avg "`group' average income (Million CLP)"
 	}
}

*graph variables
foreach v in $ineqvars average {
	*quietly replace `v' = `v' * 100 
	foreach c in $svy_countries {
		di as result "`c' - " _continue
		local c2 = strlower("`c'")
		local glines_`v' `glines_`v'' ///
			(connected `v' year if country == "`c'", ///
			lcolor(${c_`c2'}) mcolor(${c_`c2'}) mfcolor(${c_`c2'}))	
	}
	
	//aesthetics 
	local ll = subinstr("`v'", "_sh", "", .)
	local yrg -.1(.1).7

	//the graph 
	graph twoway `glines_`v'', yline(0, lpattern(dash) lcolor(black)) ///
		ytitle("${lname_`ll'} - Net Wealth") ///
		xtitle("") ylabel(`yrg', $lab_opts) ///
		xlabel(2006(2)2020, $lab_opts) $graph_scheme ///
		legend(off ///
		/*order(1 "Chile" 2 "Colombia" 3 "Mexico" 4 "Uruguay") col(1)*/) 
	qui graph export ///
		"figures/surveys/ineqstats/variables/`v'.pdf", replace
}

//Loop over population groups 
foreach group in $groups {	

	di as result "decomposing group `group' at $S_TIME..."
	
	preserve
		
		//loop over variables to graph 
		local iter = 1 
		foreach v in `varlist_`group'' {
			
			display as text "   preparing variable `v' at $S_TIME"
		
			//percentage 
			*quietly replace `v' = `v' * 100 if `iter' == 1 
			
			//generate stack variables 
			quietly gen `v'_a = `group'_sh * `v'
			local st_`group'_`type'_`class' ///
				"`v'_a `st_`group'_`type'_`class''"
			
			//chose color and legend-label
			foreach w in nfi_ass fin_ass ton_lia {
				if strpos("`v'", "`w'") local v_col ${col_`w'}
				if strpos("`v'", "`w'") local v_lab ${lab_`w'}
				*if strpos("`v'", "`w'") di as result "`v' matches `w' "
			}
			
			//prepare legend
			local ll_`group'_`type'_`class' ///
				`ll_`group'_`type'_`class'' label(`iter' "`v_lab'")
			
			//lines to add to plot 
			local alines_`group'_`type'_`class' ///
				`alines_`group'_`type'_`class'' ///
				(bar f_`v'_a year, color(`v_col') lwidth(none))
				
			//count iterations 
			local iter = `iter' + 1
			local iter_endloop = `iter'
			
		}
	
		//Stack variables  
		display as text "   Stacking areas at $S_TIME"
		quietly cap drop f_*
		genstack `st_`group'_`type'_`class'', gen(f_)
		
		//handle missing values 
		foreach var in `st_`group'_`type'_`class''{
			quietly replace f_`var' = . if f_`var' == 0 
		}
		
		//Graph composition of each country by group
		quietly levelsof country if !missing(gini), local(graph_ctries)
		foreach  c in `graph_ctries' { 
		
			display as text "      preparing data for `c' at $S_TIME"
		
			//Legend label for group in loop
			if "`group'" == "b50" local labg "Bottom 50% Share"
			if "`group'" == "m40" local labg "Middle 40% Share"
			if "`group'" == "t10" local labg "Top 10% Share"
			if "`group'" == "t1" local labg "Top 1% Share"
			
			//add name to legend 
			local iter_`c' = `iter_endloop'
			local ll_`group'_`type'_`class' `ll_`group'_`type'_`class'' ///
				label(`iter_`c'' "`labg'")
			
			//add a line for the group's share
			local graph_share (connected `group'_sh year, msize(normal) ///
				color(black) mcolor(black) mfcolor(white)) 
			if ("`group'" == "tot") local graph_share ""
			
			//graph composition 
			graph twoway `alines_`group'_`type'_`class'' ///
				`graph_share' ///
				 if country == "`c'", yline(0) xtitle("") ///
				ytitle("${lname_`group'} - Share of Net Wealth") ///
				ylabel(-.1(.1).8, $lab_opts) ///
				xlabel(2006(2)2020, $lab_opts) ///
				legend(`ll_`group'_`type'_`class'') $graph_scheme	
			capture graph export ///
			"figures/surveys/ineqstats/countries/`c'_`group'_raw.pdf", replace
		}
		
	restore
}	

