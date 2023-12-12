// This program computes distributional statistics
// for each country and year specified
// Authors: Mauricio De Rosa, Ignacio Flores, Marc Morgan (2019)

program ineqstats_wealth_old 
	version 11 
	syntax name [,TIme(numlist max=2) weight(string) ///
		EXPort(string) EDad(real 20) ///
		EXTension(string) SVYPath(string) SMOOTHtop ///
		AReas(string) TYPe(string) BFM BCKTavgs]  ///
		DEComposition(string)
		
	*---------------------------------------------------------------------------
	*PART 0: Check inputs
	*---------------------------------------------------------------------------
	
	//Prepare table to display some info
	display as text "{hline 65}"
	display as text "INEQSTATS Settings:"
	display as text "{hline 65}"
	
	//Check time  
	if ("`time'" != "") {
		if (wordcount("`time'") == 1) {
			display as error "Option time() incorrectly specified:" ///
				" Must contain both the first and last values" ///
				" Default is 2000 and 2017 respectively."
			exit 198
		}
		local first_period: word 1 of `time'
		local last_period: word 2 of `time'
		display as text "Period: `first_period' - `last_period'"
	}
	else {
		local first_period = 2000
		local last_period = 2018
		display as text "Period: `first_period' - `last_period' (default)" 
	}
	
	//Weights
	if ("`weight'" == "") {
		local weight "_fep"
		display as text "Weight: `weight' (default)"
	} 
	else {
		display as text "Weight: `weight'"
	} 
	
	//Income //Now total income is the sum of components, we can put an option to change it maybe
	/*
	if ("`decomposition'" != "" & "`inc_`c'_`period''" == "") {
		display as text "Total Income is the sum of 'decomposition' items (default)"
	}
	else {
		display as text "Income: `inc_`c'_`period''"
	}
	*/
	
	//Decomposition
	if ("`decomposition'" != "") {
		display as text "Decomposing by: `decomposition'"
	}
	else{
		display as text "No decomposition"
	}
	
	//Type of survey
	if ("`type'" == "") {
		local type "harmonised"
		display as text "Survey type: `type' (default)"
	}
	else {
		display as text "Survey type: `type'"
	}
	
	//Close table
	display as text "{hline 65}"
	
	//Check if export is specified when using summarize
	if ("`namelist'" == "summarize"  & "`export'" == "") {
		display as error "If you use the summarize option without specifying" ///
			" an export path, data will be lost"
		exit 1 
	}
	
	//Decompositions and extensions 
	foreach w in `decomposition' {
		local decomp_suffix "`decomp_suffix' `w'`extension'"
	}

	*---------------------------------------------------------------------------
	*PART 1: Summary statistics (build excel files & sheets)
	*---------------------------------------------------------------------------
	
	if ("`namelist'" == "summarize") {
	
		// Loopy loops
		foreach c in `areas' {
			forvalues period = `first_period'/`last_period' {
				
				
				// Open data
				clear
				qui cap use "`svypath'/`c'/output/`c'_`period'.dta"	
	
				//drop any temporary variable that was saved mistakently
				cap drop __* 	
			
				// Only if file exists
				cap assert _N == 0
				if _rc != 0 {
					
					*check variables independently for debugging 
					foreach var in `decomp_suffix' {
						cap confirm variable `var', exact
						if _rc != 0 di as error "variable `var' not found"
					}
			
					//check variables
					cap confirm variable `decomp_suffix', exact
					if _rc == 0 {
					
						tempvar ftile ftile_clean freq F fy cumfy L d_eq ///
							p1 p2 bckt_size cum_weight wy freq_t10 F_t10 ///
							auxinc smooth_income bckt_pop
						
						// Keep adults only
						*qui drop if edad < `edad'
					
						// scale incomes for BFM adjusted surveys 
						if ("`BFM'" != "") {
							foreach inc in `decomp_suffix' {
								qui replace `inc' = `inc' * _factor
							}
						}
						
						//Get total income and average
						if ("`decomposition'" != "") {
							//display as text "`decomp_suffix'"
							tempname inc_`c'_`period'
							qui egen `inc_`c'_`period'' = ///
								rowtotal(`decomp_suffix')
						}
						*qui sum `inc_`c'_`period'' [w=`weight']
						*local avg = r(mean)	
						
						//write cdf down 
						qui sum	`weight', meanonly
						local poptot = r(sum)
						sort `inc_`c'_`period''
						quietly	gen `freq' = `weight' / `poptot'
						quietly	gen `F' = sum(`freq'[_n - 1])	
						
						*Fit Pareto to top X%
						if ("`smoothtop'" != "") {
							//get average income of the top X%
							local p0 = 0.9
							qui sum `inc_`c'_`period'' [fw=`weight'] ///
								if `F' >= `p0' 
							local a = r(mean)
							
							*get ranks within top 10% (and save b)
							qui sum `weight' if `F' >= `p0', meanonly 
							local popt10 = r(sum)
							qui gen `freq_t10' = `weight' / `popt10' 
							qui gen `F_t10' = 1 - sum(`freq_t10'[_n-1]) ///
								if `F' >= `p0'
							
							*define b and mu (threshold of X%)
							qui gen `auxinc' = `F_t10' * `inc_`c'_`period'' 
							qui sum `auxinc' [fw= `weight'], meanonly
							local b = r(mean) 
							qui sum `inc_`c'_`period'' ///
								if `F' >= `p0', meanonly 
							local mu = r(min) 
							
							*get xi and sigma 
							local xi = (`a' - 4*`b' + `mu' ) / (`a' - 2*`b')
							local sigma = (`a'-`mu') * (2*`b'-`mu') / (`a'-2*`b')
							
							*smoothen the top X% (w/o changing topavg)
							qui gen `p1' = `F' 
							qui gen `p2' = `F'[_n+1]
							qui gen `smooth_income' = ///
								`mu' + `sigma'/(`p2' - `p1')* ///
								(-((-1 + `p0')/(-1 + `p1'))^`xi' - ///
								((-1 + `p0') / (-1 + `p2'))^`xi'*(-1 + `p2') ///
								+ `p2' - `p2'*`xi' + `p1'*(-1 + ((-1 + `p0') / ///
								(-1 + `p1'))^`xi' + `xi'))/((-1 + `xi')*`xi') ///
								if _n != _N
							qui replace `smooth_income' = ///
								(`mu' *(-1 + `xi')*`xi' - `sigma'* ///
								(-1 + ((-1 + `p0')/(-1 + `p1'))^`xi' + `xi')) ///
								/((-1 + `xi')*`xi') if _n == _N
							*save correction factor 
							qui gen smooth_factor = ///
								`smooth_income' / `inc_`c'_`period'' ///
								if `F' >= `p0'
							qui replace `inc_`c'_`period'' = `smooth_income' ///
								if `F' >= `p0'	
						}
							
						*Estimate gini
						quietly	gen `fy'= `freq' * `inc_`c'_`period''
						quietly	gen `cumfy' = sum(`fy')
						qui sum `cumfy', meanonly
						local cumfy_max = r(max)
						quietly	gen `L' = `cumfy' / `cumfy_max'
						qui gen `d_eq' = (`F' - `L') * `weight' / `poptot'
						qui sum	`d_eq', meanonly
						local d_eq_tot = r(sum)
						local gini = `d_eq_tot'*2
						
						// Classify obs in 127 g-percentiles
						cap qui egen `ftile' = cut(`F'), ///
							at(0(0.01)0.99 0.991(0.001)0.999 ///
							0.9991(0.0001)0.9999 0.99991(0.00001)0.99999 1)
								
						if _rc == 0 {
						
							// Top average 
							gsort -`F'
							qui gen `wy' = `inc_`c'_`period'' * `weight'
							cap drop topavg
							qui gen topavg = sum(`wy') / sum(`weight')
							
							*topaverages decomposition 
							foreach v in `decomposition' {
								qui replace `v'`extension' = ///
									`v'`extension' * smooth_factor ///
									if !missing(smooth_factor)
								tempvar wy_`v'
								qui gen `wy_`v'' = `v'`extension' * `weight'
								qui gen topavg_`v' = sum(`wy_`v'') / sum(`weight')
							}
							sort `F'
							
							/*
							*check sum of components equals tot income 
							qui egen test_decomp = rowtotal(`decomp_suffix') 
							qui gen test_inc = `inc_`c'_`period''
							qui gen test_decomp2 = test_decomp / `inc_`c'_`period'' * 100
							exit 1
							*/
							
							//top shares
							*qui gen topshare = (topavg / `avg') * (1 - `F')
							*qui replace topshare = 1 if topshare > 1 
							
							//composition 
							foreach v in `decomposition' {
								
								/*
								//top share of specific items 
								local topavg_1_`v' = topavg_`v'[1]
								qui gen topsh_`v' = ///
									(topavg_`v' / topavg_`v'[1]) * (1 - `F') 
								qui replace topsh_`v' = 1 if topsh_`v' > 1	
								qui label var topsh_`v' "As % of total income item"
								//What share of total income by item?
								qui local sh_`v'_`c'_`period' = ///
									topavg_`v'[1] / topavg[1] 
								*/	

								//prepare lines bracket composition 
								local list_coll_`c'`period' "`list_coll_`c'`period'' bckt_avg_`v'=`v'"
							}
							
							//categorize ppl 
							tempvar maxim
							qui gen posi_liab = abs(ton_lia)
							local allpos nfi_ass fin_ass posi_liab
							qui egen `maxim' = ///
								rowmax(`allpos')
							foreach vv in `allpos' {
								qui gen ch_`vv' = 0
								qui replace ch_`vv' = `weight' ///
									if `vv' == `maxim' & `vv' != 0 
							}
							tempvar tch 
							qui egen `tch' = rowtotal(ch_*)
							qui gen ch_non_ass = 0 
							qui replace ch_non_ass = `weight' if `tch' == 0 
							
							// Collapse to 127 percentiles 
							qui collapse ///
								(min) thr = `inc_`c'_`period'' ///
								(mean) bckt_avg = `inc_`c'_`period'' ///
								`list_coll_`c'`period''  ///
								(min) `ftile_clean' = `F' ///
								(sum) bckt_sum_tot = `inc_`c'_`period'' ///
								(rawsum) ch_* `weight' ///
								[fw = `weight'], by (`ftile')	
														
							foreach vv in `allpos' non_ass {
								qui replace ch_`vv' = ///
									ch_`vv' / `weight' * 100
							}	
							qui rename ch_posi_liab ch_ton_lia 
							tempfile collapsed_form
							qui save `collapsed_form'
						
							if _rc == 0 {
								
								// build 127 percentiles again from scratch
								clear
								qui set obs 127
								qui gen `ftile_clean' = (_n - 1)/100 in 1/100
								qui replace `ftile_clean' ///
									= (99 + (_n - 100)/10)/100 in 101/109
								qui replace `ftile_clean' ///
									= (99.9 + (_n - 109)/100)/100 in 110/118
								qui replace `ftile_clean' ///
									= (99.99 + (_n - 118)/1000)/100 in 119/127			
								*append clean cuts 	
								qui append using `collapsed_form'
								qui sort `ftile_clean' 
											
								*interpolate data 
								qui ds `ftile_clean' `ftile', not 
								foreach var in `r(varlist)' {
									qui mipolate `var' `ftile_clean', ///
										gen(ip_`var') forward 
									qui drop `var'
									qui rename ip_`var' `var'
								}
								
								*keep clean cuts 
								qui keep if missing(`ftile')
								qui drop `ftile'
								qui rename `ftile_clean' `ftile'
								qui replace `ftile' = ///
									round(`ftile' * 100000)
								
								*get bracket population shares 
								qui gsort -`ftile' 
								qui gen `bckt_pop' = `ftile'[_n-1] - `ftile'  
								qui replace `bckt_pop' = 1 ///
									if `ftile' == 99999	
								qui gen sum_pop = sum(`bckt_pop')	
								
								*generate vars to enforce composition
								tempvar tot_decomp ratio_decom assets ///
									ratio_AD diff diff_ass diff_deb new_ratio 
								qui egen `tot_decomp' = rowtotal(bckt_avg_*)
								qui gen `ratio_decom' = bckt_avg / `tot_decomp'
								*exception for negative ratios 
								*(keeping asset-to-debt ratio constant)
								qui gen `assets' = `tot_decomp' - bckt_avg_ton_lia
								qui gen `ratio_AD' = `assets' / (-bckt_avg_ton_lia + `assets')
								qui gen `diff' = bckt_avg - `tot_decomp'
								qui gen `diff_ass' = `diff' * `ratio_AD'							
								qui gen `diff_deb' = `diff' * (1 - `ratio_AD') 
								qui gen `new_ratio' = ///
									(`assets' + `diff_ass') / (`assets') 
									
		
								*loop over variables
								qui ds thr bckt_sum_tot sum_pop ch_* __*, not  
								foreach v in `r(varlist)' {
									
									local ext = subinstr("`v'", "bckt_avg", "", .) 
									
									*enforce consistency of components 
									if !inlist("`v'", "bckt_avg") {
										qui replace `v' = `v' * `ratio_decom' ///
										if `ratio_decom' > 0 ///
										& !missing(`ratio_decom')
									}
									if inlist("`ext'", "debt") {
										qui replace `v' = `v' + `diff_deb' ///
											if `ratio_decom' < 0 	
									} 
									if !inlist("`ext'", "debt", "") {
										qui replace `v' = `v' * `new_ratio' ///
											if `ratio_decom' < 0 & ///
											`new_ratio' > 0 
									}
									
									*compute top averages	
									qui gen fy`ext' = `v' * `bckt_pop' 
									qui gen sum_fy`ext' = sum(fy`ext')
									qui gen topavg`ext' = sum_fy`ext' / sum_pop
									
									*get general average 
									qui sum topavg`ext' if `ftile' == 0 
									local avg`ext' = r(sum)
									
									*get top shares 
									qui gen topsh`ext' ///
										= topavg`ext' / `avg`ext'' * ///
										(sum_pop / 100000 )
									
									*get bracket shares 
									qui gen s`ext' = `v' / `avg`ext'' * ///
										(`bckt_pop'  / 100000)
								}
								
								
								*go back to decimals 
								qui replace `ftile' = `ftile' / 100000
								qui replace `bckt_pop' = `bckt_pop' / 100000
								
								*sort 
								sort `ftile'
								qui gen ftile = `ftile'	
								
								*clean
								qui rename topsh topshare 
								
								//What share of total income by item?
								foreach v in `decomposition' {
									qui local sh_`v'_`c'_`period' = ///
										topavg_`v'[1] / topavg[1] 
								}
				
								// Total average  
								qui gen average = .
								qui replace average = `avg' in 1		
								
								// Inverted beta coefficient
								qui gen b = topavg/thr		
								
								// Fractile
								qui rename ftile p
								
								// Year
								qui gen year = `period' in 1
								qui gen country = "`c'" in 1	
								
								// Write Gini
								qui gen gini = `gini' in 1
							
								if "`bcktavg'" != "" local addvars bckt_sum_tot bckt_sum_*
								
								*composition as %
								foreach dv in `decomposition' {
									qui gen sh_`dv' = ///
										bckt_avg_`dv' / bckt_avg 
								}
						
								
								// Order and save	
								order country year gini average p thr bckt_avg s  topavg sh_* ///
									topshare b topavg_* topsh* `addvars'
								keep country year gini average p thr bckt_avg s topavg ///
									topshare b	topavg_* topsh* `addvars' sh_* ch_*
								tempname mat_sum
								mkmat gini average p thr bckt_avg s topavg ///
									topshare b topavg_*, matrix(`mat_sum')
								mkmat gini average p thr bckt_avg s topavg ///
									topshare b topavg_*, matrix(_mat_sum)	
								// Export to Excel
								if ("`export'" != "") {
									qui export excel using "`export'", ///
									firstrow(variables) sheet("`c'`period'") ///
									sheetreplace keepcellfmt  	
								}
								
								display as text "ineqstats (05a): `c' `period' saved at $S_TIME"
								
								//Fetch some summary stats for 1ry panel
								local b50_sh_`c'_`period' = 1 - topshare[51]
								local m40_sh_`c'_`period' = topshare[51] - topshare[91]
								local t10_sh_`c'_`period' = topshare[91]
								local t1_sh_`c'_`period' = topshare[100]
								local gini_`c'_`period' = gini[1]
								local average_`c'_`period' = average[1]
								
								//Data for 2ry summary stats (composition)
								local it_test = 1 
								local it_test2 = 1 
								foreach v in `decomposition' {
									local b50c_`v'_`c'`period' = ///
										(1 - topsh_`v'[51]) * ///
										`sh_`v'_`c'_`period'' ///
										/ `b50_sh_`c'_`period''
									local m40c_`v'_`c'`period' = ///
										(topsh_`v'[51] - topsh_`v'[91]) * ///
										 `sh_`v'_`c'_`period'' / ///
										`m40_sh_`c'_`period''
									local t10c_`v'_`c'`period' = ///
										topsh_`v'[91] * ///
										`sh_`v'_`c'_`period'' ///
										/ `t10_sh_`c'_`period''
									local t1c_`v'_`c'`period' = ///
										topsh_`v'[100] * ///
										`sh_`v'_`c'_`period'' ///
										/ `t1_sh_`c'_`period''	
									
									*check consistency (sum of group shares by inc)
									/*di as result "sum of group shares by `v': " ///
										(1 - topsh_`v'[51]) + ///
										(topsh_`v'[51] - topsh_`v'[91]) + ///
										topsh_`v'[91]
									*/	
										
									*check consistency (sum of total income components)	
									*di as result "`v' share of tot: " `sh_`v'_`c'_`period''
									if `it_test2' == 1 local test_tots2_`period' `sh_`v'_`c'_`period''
									else local test_tots2_`period' `test_tots2_`period'' + `sh_`v'_`c'_`period''
									if `it_test2' == 1 local it_test2 = 0
									
									*check consistency (sum of components by group)
									foreach g in b50 m40 t10 t1 {
										*di as result "`g'c_`v'_`c'`period'" "--> ``g'c_`v'_`c'`period'' "
										if "``g'c_`v'_`c'`period''" != "." {
											if `it_test' == 1 {
												local `g'test_`period' ///
													``g'c_`v'_`c'`period''	
											} 
											if `it_test' != 1 {
												local `g'test_`period' ///
													``g'test_`period'' + ``g'c_`v'_`c'`period''
											} 
											if `it_test' == 1 local it_test = 0 
										}
									}
								}
								
								foreach g in b50 m40 t10 t1 {
									di as result "`g' test `period': " ``g'test_`period''
								}
								
								di as result "Test of totals (sum of components): " ///
									`test_tots2_`period''
							
							}
							
							else {
								display as error "There was a problem with " _continue
								display as error "`c' `period' (skipped)"
							}
						
						}
						
						else {
							display as error "There was a problem with " _continue
							display as error "`c' `period' (skipped)"
						}
					}
					
					else {
					
						display as text ///
						"Missing variables in `c' `period'" ///
						" (skipped)"
						
					}
				}	
			}
		}
		
		//Summarize main info for all countries
		clear 
		local nobs = ///
			wordcount("`areas'") * (1 + `last_period' - `first_period')
		set obs `nobs'
		qui gen country = ""
		
		//Summarize primary variables 
		preserve
		
			//Generate empty vars
			foreach v in "year" "gini" "average" "b50_sh" ///
				"m40_sh" "t10_sh" "t1_sh" {
				qui gen `v' = .
			}
			
			//Fill variables with a loop
			local iter = 1 
			foreach c in `areas' {
				forvalues period = `first_period'/`last_period'{
					qui replace country = "`c'" in `iter'
					qui replace year = `period' in `iter'
					foreach v in "gini" "average" "b50_sh" ///
						"m40_sh" "t10_sh" "t1_sh" {
						if ("``v'_`c'_`period''" != "") {
							qui replace `v' = ``v'_`c'_`period'' ///
								in `iter'
						}
					}
				local iter = `iter' + 1
				}	
			}
			
			//Save in a sheet (country-year)
			if ("`export'" != "") {
				qui export excel using "`export'", ///
				firstrow(variables) sheet("Summary") ///
				sheetreplace keepcellfmt  	
			}
			display as text "Summary saved at $S_TIME"
		
		restore
		
		//Summarize info for composition
		
		//Empty variables
		qui gen year = . 
		foreach group in "tot" "b50" "m40" "t10" "t1" {
			foreach v in `decomposition' {
				qui gen `group'_sh_`v' = . 
			}
		}
		
		//Fill variables with locals (composition)
		local iter = 1 
		foreach c in `areas' {
			forvalues period = `first_period' / `last_period'{
				qui replace country = "`c'" in `iter'
				qui replace year = `period' in `iter'
				foreach group in "tot" "b50" "m40" "t10" "t1" {
					foreach v in `decomposition' {
						if ("`group'" != "tot" & ///
							"``group'c_`v'_`c'`period''" != "") {
							qui replace `group'_sh_`v' = ///
								``group'c_`v'_`c'`period'' ///
								in `iter'
						}		
						if ("`group'" == "tot" & ///
							"`sh_`v'_`c'_`period''" != "") {
							qui replace tot_sh_`v' = ///
							`sh_`v'_`c'_`period'' in `iter'	
						} 
					}
				}	
			local iter = `iter' + 1	
			}
		}
		
		/*
		//test that sum of components equals 1 
		foreach group in "tot" "b50" "m40" "t10" "t1" {
			qui ds `group'_sh_*
			local varlist_`group' "`r(varlist)'"
			di as result wordcount("`varlist_`group''") " vars:" _continue
			di as text " `varlist_`group''"
			qui egen test_`group' = rowtotal(`varlist_`group'')
			tab test_`group'
			*assert test_`group' == 1 
		}
		*/
		
		//Save in a sheet (country-year)
		if ("`export'" != "") {
			qui export excel using "`export'", ///
			firstrow(variables) sheet("Composition") ///
			sheetreplace keepcellfmt  	
		}
	}		
	
	else {
		display as error "`namelist' is not a valid subcommand"
		exit 198
	}
	
end	
