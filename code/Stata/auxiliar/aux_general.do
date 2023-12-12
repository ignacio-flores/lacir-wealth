*General directoty of paths, variable names and other stuff we want to 
*define only once 

*I. Preliminary 
if $aux_part == "preliminary" {
	
	*paths to files 
	global summary results/ineqstats/
	global ado_file code/stata/ado_files/
	global fin_accounts_dta data/financial-accounts/financial-accounts.dta
	global housing_dta data/housing/housing.dta
	global fon_soberan_dta data/financial-accounts/fondos-soberanos.dta
	global business_cap_dta data/Nomina_personas_juridicas/DTA/business_capital.dta
	global land_sii_dta data/agricultural_land/land-data-sii.dta
	global totals_efh_dta data/EFH/long_data/totals_efh.dta
	global wealth_svy data/EFH/Bases_imputadas/
	global infl_dta data/infl_xrates_wid_wb.xlsx
	global wealth_decomp nfi_ass fin_ass ton_lia  
	global svy_countries CHL COL MEX URY 
	global path_surveys data/surveys
	global path_results results/ineqstats/raw_surveys
	global path_adofile code/Stata/ado_files/ineqstats_wealth_ado/.
	global path_auxfile code/Stata/auxiliar
	
	*I. Encuesta Financiera de Hogares 
	
	*I:1 list variables -----
	
	*2014-2017: with and without overlap 
	global efh_newvars_over act_otp act_auto act_finfija act_finvar act_vp ///
		act_toth cap_pen_ent d_nhip d_hip d_toth
	global efh_newvars_nover act_otros act_ahcta
	*2007-2011:	
	global efh_oldvars otp a_auto a_fijo a_var vp atoth cap_pen dconsh ///
		dhiph dtoth	
	*All variables (new names)
	global efh_allvars ${efh_newvars_over} ${efh_newvars_nover}
	*decomposition 
	global decomp_efh pension stock cash otherfin debt housing otherreal otherestate auto
	
	*I:2 Labels -----
	
	*EFH variable labels 
	//CHL
	global lab_act_otp "Otros activos Reales" 
	global lab_act_auto "Activos automotrices" 
	global lab_act_finvar "Activos financieros variables" 
	global lab_act_finfija "Activos financieros fijos"  
	global lab_act_vp "Vivienda propia"   
	global lab_act_toth "Activos totales"  
	global lab_cap_pen_ent "Cuenta capitalizacion entrevistado" 
	global lab_d_nhip "Deuda no hipotecaria"  
	global lab_d_hip "Deuda hipotecaria"  
	global lab_d_toth "Deuda total" 
	global lab_act_otros "Otros activos"
	global lab_act_ahcta "Cash" 
	
	// for all
	cap label var weight 	"weight"
	cap label var inc_tot	"total income"
	cap label var id_hou	"household id"
	cap label var hou_ass	"housing assets"
	cap label var hou_lia	"housing liabilities"
	cap label var bus_ass	"business assets"
	cap label var bus_lia	"business liabilities"
	cap label var dur_ass	"durables"
	cap label var dur_lia	"durables liabilities"
	cap label var oth_lia	"other liabilities"
	cap label var fin_ass	"financial assets"
	cap label var nfi_ass   "non financial assets"
	cap label var pen_ass	"pensions assets"
	cap label var tot_ass	"total assets"
	cap label var tot_lia	"total liabilities"
	cap label var net_wth	"net worth assets"
	
	cap label var hou_ass_pc	"housing assets (pc)"
	cap label var hou_lia_pc	"housing liabilities (pc)"
	cap label var bus_ass_pc	"business assets (pc)"
	cap label var bus_lia_pc	"business liabilities (pc)"
	cap label var dur_ass_pc	"durables (pc)"
	cap label var dur_lia_pc	"durables liabilities (pc)"
	cap label var oth_lia_pc	"other liabilities (pc)"
	cap label var fin_ass_pc	"financial assets (pc)"
	cap label var pen_ass_pc	"pensions assets (pc)"
	cap label var tot_ass_pc	"total assets (pc)"
	cap label var tot_lia_pc	"total liabilities (pc)"
	cap label var net_wth_pc	"net worth assets (pc)"
	
	*Colors for graphs 
	global col_cas ebblue*.3
	global col_aut black*.3
	global col_sto ebblue*.6
	global col_pen ebblue
	global col_hou dkgreen
	global col_rre dkgreen*.3
	global col_deb cranberry
	global col_erf sand
	global col_est dkgreen*.6
	
	*Labels for graphs 
	global lab_fin_ass	"Financial assets"
	global lab_nfi_ass  "Non-financial assets"
	global lab_pen_ass	"Pensions assets"
	global lab_tot_ass	"Total assets"
	global lab_tot_lia	"Total liabilities"
	global lab_ton_lia	"Total liabilities"
	
	global lab_fin "Financial assets"
	global lab_nfi "Non-financial assets"
	global lab_lia "Liabilities"
	global lab_lia "Liabilities"
	global lab_nwt "Net worth"
	
	global lab_chl "Chile"
	global lab_mex "Mexico"
	global lab_ury "Uruguay"
	global lab_col "Colombia"
	
	//group labels 
	global lname_t1  "Top 1%"
	global lname_t10 "Top 10%"
	global lname_m40 "Middle 40%"
	global lname_b50 "Bottom 50%"
 	
	
	//axis label options 
	global lab_opts labsize(small) grid angle(horizontal)

	//last bit of a graph
	global graph_scheme scheme(s1color) subtitle(,fcolor(white) ///
	lcolor(bluishgray)) graphregion(color(white)) ///
	plotregion(lcolor(bluishgray)) scale(1.2)
	
	//axis label options 
	global ylab_opts labsize(medium) grid labels angle(horizontal)
	global xlab_opts labsize(medium) grid labels angle(45)
	
	//country colors
	global c_arg "eltblue"
	global c_bol "eltgreen"
	global c_bra "midgreen"
	global c_chl "cranberry"
	global c_col "gold"
	global c_cri "purple"
	global c_ecu "stone"
	global c_dom "black"
	global c_cym "lavender"
	global c_per "gs7"
	global c_mex "dkgreen"
	global c_ury "ebblue"
	global c_slv "maroon"
	global c_ven "red"
	global c_brb "orange"
	global c_gtm "gs15"
	global c_bmu "sienna"
	global c_cub "gs10"
	
	//variables colors 
	global c_nfi "eltgreen"
	global c_fin "eltblue"
	global c_lia "orange"
	global c_nwt "black"
		 
}
  
