*settings 
clear 
global data "data/surveys"

*loop over years 
forvalues y=2010/2018 {

	qui use "$data/COL/input/IEFIC_`y'.dta", clear
	di as result "`y'"

	qui gen weight 			= FEX_C
		qui replace weight = round(weight) 
	if inlist(`y',2017,2018)  qui gen id_hhd = DIRECTORIO
	if !inlist(`y',2017,2018) qui gen id_hhd = DIRECTORIO_GEIH
	qui gen id_ind			= LLAVE_PER_GEIH
	qui gen inc_tot 		= INGTOTOB
	qui gen id_hou 			= id_hhd
	qui gen sex 			= P35
	qui gen order			= ORDEN

	foreach v in 	P2461 P2484 P2471_4 P2475_4 P5003_4 P2983 P2487 P2498 ///
					P2501_4 P2490_4 P2999_4 P2542_4 P2560_4 P2623_4 P2637_4 ///
					P2772_4 P2736_4 P2696_4 P2693_4 P2869 P1136 P1421 P2962 ///
					P2968 P2971 P2965 P2503 {
		qui replace `v' = 0 if missing(`v') 
	}

// Define general variables-----------------------------------------------------

	// main residence and others
	qui gen hou_ass  = P2461 + P2484  
	qui gen hou_lia	 = P2471_4 + P2475_4 + P5003_4 
	qui gen bus_ass  = P2983 + P2487 + P2498
	qui gen bus_lia  = P2501_4 + P2490_4 + P2999_4
	
	// cars, boats, etc
	qui gen dur_ass  = P2503	
	qui gen dur_lia	 = P2542_4 + P2560_4 // credit cars

	qui gen oth_lia  = P2623_4 + P2637_4 + P2772_4 + P2736_4 + P2696_4 + P2693_4

	qui gen pen_ass  = P2965
	
	
// Define main variables--------------------------------------------------------
	tempvar fin_ass nfi_ass tot_lia tot_ass net_wth

	qui gen fin_ass  = P2869 + P1136 + P1421 + P2962 + P2968 + P2971 + pen_ass 
	qui gen nfi_ass  = hou_ass + bus_ass + dur_ass
	qui gen tot_lia	 = hou_lia + bus_lia + dur_lia + oth_lia

	foreach var in fin_ass nfi_ass tot_lia {
		qui replace `var' = 0 if inlist(`var',98,99)
	}
	
	global aux_part " "preliminary" " 
	qui do "code/Stata/auxiliar/aux_general.do"				
	qui gen ton_lia = -tot_lia 
	qui replace ton_lia = 0 if missing(ton_lia)
	qui label var ton_lia "Total liabilities (negative)"
	
	collapse (sum) fin_ass nfi_ass tot_lia ton_lia (mean) weight, by(id_hou)
	qui gen tot_ass			= nfi_ass + fin_ass
	qui gen net_wth			= tot_ass - tot_lia
			
	qui save "$data/COL/output/COL_`y'.dta", replace
	
}
