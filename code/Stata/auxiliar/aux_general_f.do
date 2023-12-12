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
	
	*Colors for graphs 
	global col_cas black
	global col_aut gs2
	global col_sto gs4
	global col_pen gs6
	global col_hou gs8
	global col_rre dimgray
	global col_deb gs10
	global col_erf gs12
	global col_est gs15
	
	*Labels for graphs 
	global lab_cas "Efectivo"
	global lab_aut "Vehiculos"
	global lab_sto "Acciones"
	global lab_pen "Pensiones"
	global lab_hou "Vivienda Principal"
	global lab_rre "Otros Act. Reales"
	global lab_deb "Deuda Total"
	global lab_erf "Otros Act. Fin."
	global lab_est "Otras viviendas"
	
	//axis label options 
	global lab_opts labsize(small) grid angle(horizontal)

	//last bit of a graph
	global graph_scheme scheme(s1color) subtitle(,fcolor(white) ///
	lcolor(bluishgray)) graphregion(color(white)) ///
	plotregion(lcolor(bluishgray)) scale(1.2)
	 
}
  