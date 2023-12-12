*settings 
clear 
global data "data/surveys"

// data with inly the first set of values (no imputations)
use "$data/URY/input/BASES/hogares_EFHU.dta", clear
keep if _mi_m==1 | (_mi_m==0 & _mi_miss==0) // first round of imputations


// General variables------------------------------------------------------------

qui mvencode a1_15 a1_38 a2_monto a2_deuda_monto b_11 b_actfin_monto h_30 ///
	h_29 a3_4 a3_8 a3_10 a3_12 a3_17 a3_21 a3_28 c_deuda_monto ///
	g_49_sup, mv(0) override

gen aux1 = 1 if !missing(a2_8_1)
gen aux2 = 1 if !missing(a2_8_2)
gen aux3 = 1 if !missing(a2_8_3)
mvencode aux1 aux2 aux3, mv(0) override
gen aux =  aux1 + aux2 + aux3

gen hom1 = 1 if a2_8_1 == 1 & !missing(a2_8_1)
gen hom2 = 1 if a2_8_2 == 1 & !missing(a2_8_2)
gen hom3 = 1 if a2_8_3 == 1 & !missing(a2_8_3)
mvencode hom1 hom2 hom3, mv(0) override
gen hom =  hom1 + hom2 + hom3

gen ishou = 0
replace ishou = 1 if aux == hom 

qui gen id_hou = hogar_id
qui gen weight = pesoEFHU 

* Housing 
qui gen 	hou_ass = 0
qui replace hou_ass = a2_monto if ishou ==1
qui replace hou_ass = hou + a1_15 

* Business
qui gen 	bus_ass = 0
qui replace bus_ass = a2_monto if ishou ==0
qui replace bus_ass = bus + h_30 if h_16 == 1 

* Pensions
qui gen pen_ass 	= 0
qui replace pen_ass = g_49_sup

* Financial
qui gen 	fin_ass = 0
qui replace fin_ass = b_11 + b_actfin_monto  
qui replace fin_ass = fin + h_30 if h_16 != 1 

*Liabilities
qui gen hou_lia 	= 0
qui replace hou_lia = a1_38 + a2_deuda_monto

qui gen dur_lia 	= 0
qui replace dur_lia = c_deuda_monto

qui gen oth_lia 	= 0

qui gen bus_lia 	= 0

* Durable goods
qui gen dur_ass		= 0
qui replace dur_ass	= a3_4 + a3_8 + a3_10 - a3_12 + a3_17 + a3_21 + a3_28

* Income
qui gen inc_tot		= 0
qui replace inc_tot	= e_6

// Main variables---------------------------------------------------------------
qui replace fin_ass 	= fin_ass + pen_ass 
qui gen 	nfi_ass 	= hou_ass + bus_ass + dur_ass
qui gen 	tot_lia		= hou_lia + bus_lia + dur_lia + oth_lia 
qui gen 	tot_ass		= nfi_ass + fin_ass
qui gen 	net_wth		= tot_ass - tot_lia

// per capita
foreach v in hou_ass hou_lia bus_ass 	///								
			bus_lia dur_ass dur_lia	 	///
			oth_lia fin_ass pen_ass 	///
			tot_ass	tot_lia net_wth 	///
			{
	qui gen `v'_pc = `v' /  j_1
}

global aux_part " "preliminary" " 
qui do "code/Stata/auxiliar/aux_general.do"	

qui gen ton_lia = -tot_lia 
	qui replace ton_lia = 0 if missing(ton_lia)
	qui label var ton_lia "Total liabilities (negative)"

qui save "$data/URY/output/URY_2013", replace



