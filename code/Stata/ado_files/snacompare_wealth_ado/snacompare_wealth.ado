// This program compares aggregate incomes in memory to those in SNA  
// for each country and year specified
// Authors: Mauricio De Rosa, Ignacio Flores, Marc Morgan (2019)

program snacompare_wealth, eclass 
	version 11 
	syntax using/ , [TIme(numlist max=2) EXT(string) ///
		EXPortexcel(string) AUXiliary(string) SHOW ESPañol ///
		GRAPHEXTRAPolate] SVYPath(string) ///
		AReas(string) WEIght(string) EDAD(numlist max=2)	
	
*---------------------------------------------------------------------------
	*PART 0: Checks and export paths
*---------------------------------------------------------------------------
	 
	//SNA data file exists
	confirm file "`using'" 
	 
	//Check time  
	if ("`time'" != "") {
		if (wordcount("`time'") == 1) {
			di as error "Option time() incorrectly specified:" ///
				" Must contain both the first and last values" ///
				" Default is 1990 and 2017 respectively."
			exit 198
		}
		local first_yr: word 1 of `time'
		local last_yr: word 2 of `time'
	}
	else {
		local first_yr = 1989
		local last_yr = 2017
		di as text "First period was automatically set to `first_yr'" ///
		" and last period to `last_yr'"
	}
	
	//save selected weight 
	local orig_weight "`weight'"
	
	//Paths to export graphs 
	global project_path cap cd "~/Dropbox/DINA-LatAm/"
	global project_path2 cap cd "D:/Dropbox/LATAM-WIL/"
	global figs_path "figures/snacompare"
	global overleaf_path cap cd ///
		"~/Dropbox/Aplicaciones/Overleaf/More Unequal or Not as Rich/Figures"
	global overleaf_path2 cap cd ///
		"D:/Dropbox/Aplicaciones/Overleaf/More Unequal or Not as Rich/Figures"
	
	*---------------------------------------------------------------------------
	*PART 1: Bring SNA totals
	*---------------------------------------------------------------------------
	
	//Loop over years and countries 
	local  iter = 1
	forvalues yr = `first_yr'/`last_yr' {
		foreach c in `areas' {
			
			//Weights 
			local weight "`orig_weight'"
			
			local iter = `iter' + 1
			global current_year = `yr'
			
			//Keep only the relevant row
			qui use `using', clear
			qui drop __*
			qui keep if country ==	"`c'" & year ==	`yr'
			
			//Continue only if data exists
			cap assert _N == 0
			if _rc != 0 {	
				
				//Get National income from wid and undata  
				local nni_`c'_`yr' = nni[1] 	
				local vars lia nfi fin nwt
				foreach v in `vars' {
					qui gen `v'_nac = `v' * `nni_`c'_`yr''
				}
				
				//Set table for log
				*di as text "{hline 50}"
				di as text "05a: Comparing aggregates for " ///
					_continue 
				di as text "`c' - `yr'"
				*di as text "{hline 50}"
					
				if ("`show'" != ""){	
					di as text "{hline 50}"
					di as text "Composition of HH inc. in sna (% of NI)"
					di as text "{hline 50}"
				}
				
				//Store sna-values in memory
				foreach v in `vars' {
					
					*total for scaling 
					qui sum `v' 	
					local `v'_nac_d = r(sum) * 100
					
					*total for scaling 
					qui sum `v'_nac
					local `v'_nac_`c'_`yr' = r(sum) 
					
					if ("`show'" != ""){
						//di on screen 
						di as text "`v': " round(``v'_nac_d', 0.1) "%"
					}
				}
				
				*---------------------------------------------------------------
				*PART 2: Compare to microdata
				*---------------------------------------------------------------	
					
				//Check existence of file
				cap confirm file ///
					"`svypath'/`c'/output/`c'_`yr'.dta"	
					
				//continue if available 	
				if _rc==0 {
					qui use ///
						"`svypath'/`c'/output/`c'_`yr'.dta", clear
						//qui replace ind_pre_imp = 0 if edad < 20

						cap drop __*
					
					if ("`show'" != ""){
						//cosmetics
						di as text "{hline 80}"
						di as text "Scal. factors by inc. type (svy to sna)"
						di as text "{hline 80}"
					}
					
					//record proportional alloc. variable by income source
					qui replace `weight' = round(`weight')
					
					//rename variables 
					qui gen fin = fin_ass 
					qui gen nfi = nfi_ass 
					qui gen lia = abs(tot_lia) 
					qui gen nwt = net_wth 
					
					foreach v in `vars' {
							
						*check if variable exists
						cap confirm variable `v', exact 
						
						if _rc == 0 {
							
							*summarize survey total
							qui sum `v' [fw = `weight'] 
							local `v'_svy = r(sum) 
							
							*scaling factor 
							local `v'_`c'_`yr'_rat	= ///
								``v'_svy' / ``v'_nac_`c'_`yr''	
							
							
							if ("`show'" != ""){
								//di scaling factors
								di as text "`v' -> " ///
									round(``v'_`c'_`yr'_rat', 0.001) 
								*di as text " --> Survey: ``v'_svy' (LCU)" ///
								*	_continue 
								*di as text " SNA: ``v'_nac_`c'_`yr''"
							}			
						}
						else {
							di as text "`v' not found"
						}
					}
					*store survey total too
					qui sum net_wth [fw = `weight'] 
					local sum_net_wth = r(sum)
					local svy_to_nni_`c'_`yr' = ///
						`sum_net_wth' / `nni_`c'_`yr'' * 100
				}
			}
			else {
				di as text "  * not found in SNA data"
			}
		}
	}	
	
	*---------------------------------------------------------------------------
	*PART 3: Summarize scaling factors 
	*---------------------------------------------------------------------------

	clear all
	tempvar aux1 aux2 aux3 
	
	//Make room for info
	local setobs = `iter' - 1
	set obs `setobs'
	qui gen country = ""
	foreach v in year `vars' svy_to_nni {
		qui gen `v' = . 
	}

	//Loop over countries 
	local iter = 1 
	local diff = `last_yr' - `first_yr' 
	foreach c in `areas' {
		local iter_plus_diff = `iter' + `diff'
		local year = `first_yr'
		forvalues n = `iter' / `iter_plus_diff' {
		
			//Fill basic variables 
			qui replace country = "`c'" in `n'
			qui replace year = `year' in `n'
			
			//Fill scaling factors 
			foreach v in `vars' svy_to_nni {
				if "`v'" == "svy_to_nni" {
					if !inlist("`svy_to_nni_`c'_`year''", "", ".") {
						qui replace svy_to_nni = `svy_to_nni_`c'_`year'' ///
							if country == "`c'" & year == `year'
					}
				}
				if !inlist("``v'_`c'_`year'_rat'", "", ".") {
					qui replace `v' = ``v'_`c'_`year'_rat' * 100 ///
						if country == "`c'" & year == `year'
				}
			}
			
			//Add one to iterations
			local iter = `iter' + 1
			local year = `year' + 1
		}
	}
	 
	qui order country year 
	qui egen checker = rowtotal(`vars')	
	qui drop if checker == 0 
	qui drop checker 

	//export ratios  
	if ("`exportexcel'" != "") {
		preserve 
			qui export excel using "`exportexcel'", firstrow(variables) ///
				sheet("ratios") sheetreplace keepcellfmt
		restore 
	}
	
	*get rid of extrapolated data 
	if "`GRAPHEXTRAPolate'" == "" {
		*foreach v in $imput_vars {
		*	qui replace `v' = . if extsna_`v' == 1
		*}
	}
	
	//Loop over variables 
	qui sort country year
	foreach v in `vars' {
		foreach c in `areas' {
			local c2 = strlower("`c'")
			local grapher1_`v' `grapher1_`v'' ///
				(connected `v' year if country == "`c'", ///
				lcolor(${c_`c2'}) mcolor(${c_`c2'}) ///
				mfcolor(${c_`c2'}))
				
		}
		if "`v'" != "svy_to_nni" {
			local ytit Survey / NA
		}
		else {
			local ytit Survey / NNI
		}
		graph twoway `grapher1_`v'' , ///
			ytitle("`ytit'") xtitle("") ///
			yline(100, lpattern(dash) lcolor(black*0.5)) ///
			ylabel(0(20)100, $ylab_opts format(%2.0f)) ///
			xlabel(2000(5)2020, $xlab_opts) ///
			$graph_scheme legend(off)		
		//Save
		qui graph export ///
			"figures/surveys/snacompare/`v'.pdf", replace
	}

	//Now graph all variables by country 
	foreach c in `areas' {

		if "`GRAPHEXTRAPolate'" != "" {
			*local pvs $per_variable_settings $per_variable_settings_e
		} 
		
		if "`español'" != "" {
			local ytit "Encuesta / Cuentas Nacionales"
		}
		else {
			local ytit "Survey / NA"
		}
		
		local it2 = 1 
		foreach v in `vars' {
			local grapher2_`c' `grapher2_`c'' ///
				(connected `v' year if country == "`c'", ///
				lcolor(${c_`v'}) mfcolor(${c_`v'}) mcolor(${c_`v'}))
					
			local legender2_`c' `legender2_`c'' ///
				`it2' "${lab_`v'}"
			local it2 = `it2' + 1	
		}
		
		//graph all variables  // 
		graph twoway `grapher2_`c'', /// 
			ytitle("`ytit'") xtitle("") ///
			yline(100, lpattern(dash) lcolor(black*0.5)) ///
			ylabel(0(20)100, $ylab_opts_white format(%2.0f)) ///
			xlabel(2005(5)2020, $xlab_opts_white ) ///
			`add_line_`c'' `add_text_`c'' ///
			$graph_scheme  legend(order(`legender2_`c''))
		//Save
		qui graph export ///
			"figures/surveys/snacompare/`c'.pdf", replace
		
	}
		
end 	

