*settings 
clear 
global data "data"
global figures "figures/forbes"
global aux_part  ""preliminary"" 
qui do "code/Stata/auxiliar/aux_general.do"  

// aggregate wealth: us dollars
tempfile wealth_wil usd_rate_wil wealth_wil_usd aux
qui wid, indicators(mpweal) clear 
qui rename value nwt_agg
qui save `wealth_wil'

qui wid, indicators(xlcusx) clear 
qui rename value usd_rate
qui merge 1:1 country year using `wealth_wil', nogen

qui gen agg_wealth_usd = nwt_agg / usd_rate 
kountry country, from(iso2c) to(iso3c) 
qui replace country = _ISO3C_
qui keep country year agg_wealth_usd
preserve
	qui keep if inlist(country, "CRI", "ARG", "BMU", "BRA", "CHL", "COL")
	qui save `aux'
restore
qui keep if inlist(country, "BRB", "CYM", "DOM", "ECU", "GTM", "MEX", "PER", "VEN")
qui append using `aux'
qui save `wealth_wil_usd'


// adult population
tempfile population
qui use "$data/Population/PopulationLatAm.dta", clear
	qui replace country = "CRI" if country  == "            Costa Rica"
	qui replace country = "ARG" if country  == "            Argentina"
	qui replace country = "BLZ" if country  == "            Belize"
	qui replace country = "BMU" if country  == "            Bermuda"
	qui replace country = "BRA" if country  == "            Brazil"
	qui replace country = "CHL" if country  == "            Chile"
	qui replace country = "COL" if country  == "            Colombia"
	*qui replace country = "CUB" if country  == "            Cuba"
	qui replace country = "BRB" if country  == "            Barbados"
	qui replace country = "CYM" if country  == "            Cayman Islands"
	qui replace country = "DOM" if country  == "            Dominican Republic"
	qui replace country = "ECU" if country  == "            Ecuador"
	qui replace country = "GTM" if country  == "            Guatemala"
	qui replace country = "MEX" if country  == "            Mexico"
	qui replace country = "PER" if country  == "            Peru"
	qui replace country = "VEN" if country  == "            Venezuela (Bolivarian Republic of)"
	qui replace country = "URY" if country  == "            Uruguay"

qui save `population'

// latam countries
global latam_ctries ""CRI" "ARG" "BMU" "BRA" "CHL" "COL" "BRB" "CYM" "DOM" "ECU" "GTM" "MEX" "PER" "VEN" " // "CUB"

tempfile forbes_latam
use "$data/ForbesGlobal/ForbesGlobal_1988_2017.dta", clear 
	qui rename countryresid country
	qui replace country = "CRI" if country  == "Costa Rica"
	qui  replace country = "ARG" if country  == "Argentina"
	qui  replace country = "BMU" if country  == "Bermuda"
	qui  replace country = "BRA" if country  == "Brazil"
	qui  replace country = "CHL" if country  == "Chile"
	qui  replace country = "COL" if country  == "Colombia"
	*qui  replace country = "CUB" if country  == "Cuba"
	qui  replace country = "BRB" if country  == "Barbados"
	qui  replace country = "CYM" if country  == "Cayman Islands"
	qui  replace country = "DOM" if country  == "Dominican Republic"
	qui  replace country = "ECU" if country  == "Ecuador"
	qui  replace country = "GTM" if country  == "Guatemala"
	qui  replace country = "MEX" if country  == "Mexico"
	qui  replace country = "PER" if country  == "Peru"
	qui  replace country = "VEN" if country  == "Venezuela"


// latam countries in forbes
qui gen 	latam_c = 0
foreach c in $latam_ctries {
 qui replace latam_c = 1 if country == "`c'"     
}

// save for aggregate latam estimates
save `forbes_latam'

// merge with population and wealth aggregates
qui merge m:1 country year using "`population'", nogen
qui merge m:1 country year using "`wealth_wil_usd'", nogen
qui egen count 		= count(wealth), by (country year) 
qui gen av_wealth 	= wealth


// graph number and share for latam's countries
qui keep if latam_c == 1


//graph
* number of billionaires by year
tempvar aux count
qui gen `aux' = 1
forvalues y = 1988/2017 {
	
	preserve
		qui keep if year == `y'
		bysort country:  gen `count' = _n
		egen num_rich = sum(`aux'), by (country)
		qui keep if `count' == 1
		qui sort num_rich	

		graph bar (mean) num_rich,  ///
			over(country, sort(1) lab(angle(45)))   ///
			$graph_scheme ///
			ytitle("N. of billionares")	///
			ylabel(0(5)50, $ylab_opts) 						
			qui graph export "$figures/forbes_`y'.pdf", replace

	restore
}

global fractiles 1000000(1000000)10000000
forvalues f = $fractiles {
	preserve
		tempfile top_1_`f'
		tempvar aux limit
		sort country year -wealth
		bysort country year: gen `aux' = _n
		gen `limit' = adultpop / `f'	
		keep if `aux' <= `limit' & count >= `limit'
		qui collapse (sum) wealth (max) agg_wealth_usd, ///
			by(country year)
	 	qui gen sh_wea = ((wealth*1000000) / agg_wealth_usd) 
	 	save `top_1_`f''		
	restore
}
* 2 all billionaires
qui collapse (sum) wealth (count) count (max) adultpop (max) agg_wealth_usd ///
	(mean)av_wealth, by(country year)
 	qui gen sh_pop 			= round((count / adultpop) * 100000000)  
 	qui gen sh_wea 			= (wealth*1000000 / agg_wealth_usd)  
	qui gen av_wealth_ctr 	= agg_wealth_usd / adultpop
	qui gen bill_avg_ratio  = (av_wealth*1000000) / av_wealth_ctr  
	

// billionaires / average ratio
twoway 												///
	(line 	bill_avg_ratio year if country == "ARG", color($c_arg))		///
	(line 	bill_avg_ratio year if country == "BMU", color($c_bmu))		///
	(line 	bill_avg_ratio year if country == "BRA", color($c_bra))		///
	(line 	bill_avg_ratio year if country == "CHL", color($c_chl))		///
	(line 	bill_avg_ratio year if country == "COL", color($c_col))		///
	(line 	bill_avg_ratio year if country == "BRB", color($c_brb))		///
	(line 	bill_avg_ratio year if country == "CYM", color($c_cym))		///
	(line 	bill_avg_ratio year if country == "DOM", color($c_dom))		///
	(line 	bill_avg_ratio year if country == "ECU", color($c_ecu))		///
	(line 	bill_avg_ratio year if country == "GTM", color($c_gtm))		///
	(line 	bill_avg_ratio year if country == "MEX", color($c_mex))		///
	(line 	bill_avg_ratio year if country == "PER", color($c_per))		///
	(line 	bill_avg_ratio year if country == "VEN", color($c_ven))		///
	(line 	bill_avg_ratio year if country == "CRI", color($c_cri))		///
	/*(line 	bill_avg_ratio year if country == "CUB", color($c_cub))	*/	///
	, 												///
	$graph_scheme 									///
	ylabel(0(50000)250000, $ylab_opts) 					///
	xlabel(1988(5)2017, $xlab_opts) 				///
	legend(off)										///
	xtitle("Year")									///
	ytitle("billionaires/average ratio.")		///
	aspect(.4)
	qui graph export "$figures/bill_avg_ratio.pdf", replace

	
	
// graph number of billionaires - all
twoway 												///
	(line 	count year if country == "ARG", color($c_arg))		///
	(line 	count year if country == "BMU", color($c_bmu))		///
	(line 	count year if country == "BRA", color($c_bra))		///
	(line 	count year if country == "CHL", color($c_chl))		///
	(line 	count year if country == "COL", color($c_col))		///
	(line 	count year if country == "BRB", color($c_brb))		///
	(line 	count year if country == "CYM", color($c_cym))		///
	(line 	count year if country == "DOM", color($c_dom))		///
	(line 	count year if country == "ECU", color($c_ecu))		///
	(line 	count year if country == "GTM", color($c_gtm))		///
	(line 	count year if country == "MEX", color($c_mex))		///
	(line 	count year if country == "PER", color($c_per))		///
	(line 	count year if country == "VEN", color($c_ven))		///
	(line 	count year if country == "CRI", color($c_cri))		///
	/*(line 	count year if country == "CUB", color($c_cub))*/		///
	, 												///
	$graph_scheme 									///
	ylabel(0(10)60, $ylab_opts) 					///
	xlabel(1988(5)2017, $xlab_opts) 				///
	legend(off)										///
	xtitle("Year")									///
	ytitle("LATAM´s billionares.")		///
	aspect(.4)
	qui graph export "$figures/forbes_number_latam.pdf", replace

// share of billionaires in adult population
qui keep if sh_pop < 500
twoway 												///
	(line 	sh_pop year if country == "ARG", color($c_arg))		///
	(line 	sh_pop year if country == "BMU", color($c_bmu))		///
	(line 	sh_pop year if country == "BRA", color($c_bra))		///
	(line 	sh_pop year if country == "CHL", color($c_chl))		///
	(line 	sh_pop year if country == "COL", color($c_col))		///
	(line 	sh_pop year if country == "BRB", color($c_brb))		///
	(line 	sh_pop year if country == "CYM", color($c_cym))		///
	(line 	sh_pop year if country == "DOM", color($c_dom))		///
	(line 	sh_pop year if country == "ECU", color($c_ecu))		///
	(line 	sh_pop year if country == "GTM", color($c_gtm))		///
	(line 	sh_pop year if country == "MEX", color($c_mex))		///
	(line 	sh_pop year if country == "PER", color($c_per))		///
	(line 	sh_pop year if country == "VEN", color($c_ven))		///
	(line 	sh_pop year if country == "CRI", color($c_cri))		///
	/*(line 	sh_pop year if country == "CUB", color($c_cub))*/		///
	, 												///
	$graph_scheme 									///
	ylabel(0(10)120, $ylab_opts) 					///
	xlabel(1990(5)2017, $xlab_opts) 				///
	legend(off)										///
	xtitle("Year")									///
	ytitle("N. billionares per 100 million adults")		///
	aspect(.4)
	qui graph export "$figures/forbes_shbill_latam.pdf", replace

// share of billionaires wealth in adult population
twoway 												///
	(line 	sh_wea year if country == "ARG", color($c_arg))		///
	(line 	sh_wea year if country == "BMU", color($c_bmu))		///
	(line 	sh_wea year if country == "BRA", color($c_bra))		///
	(line 	sh_wea year if country == "CHL", color($c_chl))		///
	(line 	sh_wea year if country == "COL", color($c_col))		///
	(line 	sh_wea year if country == "BRB", color($c_brb))		///
	(line 	sh_wea year if country == "CYM", color($c_cym))		///
	(line 	sh_wea year if country == "DOM", color($c_dom))		///
	(line 	sh_wea year if country == "ECU", color($c_ecu))		///
	(line 	sh_wea year if country == "GTM", color($c_gtm))		///
	(line 	sh_wea year if country == "MEX", color($c_mex))		///
	(line 	sh_wea year if country == "PER", color($c_per))		///
	(line 	sh_wea year if country == "VEN", color($c_ven))		///
	/*(line 	sh_wea year if country == "CUB", color($c_cub))*/		///
	, 												///
	$graph_scheme 									///
	ylabel(0(0.01)0.08, $ylab_opts) 					///
	xlabel(1995(5)2017, $xlab_opts) 				///
	legend(off)										///
	xtitle("Year")									///
	ytitle("Billionaires wealth share")		///
	aspect(.4)
	qui graph export "$figures/forbes_shwea_latam.pdf", replace

// aux: legend	
twoway 												///
	(line 	sh_wea year if country == "ARG", color($c_arg))		///
	(line 	sh_wea year if country == "BMU", color($c_bmu))		///
	(line 	sh_wea year if country == "BRA", color($c_bra))		///
	(line 	sh_wea year if country == "CHL", color($c_chl))		///
	(line 	sh_wea year if country == "COL", color($c_col))		///
	(line 	sh_wea year if country == "BRB", color($c_brb))		///
	(line 	sh_wea year if country == "CYM", color($c_cym))		///
	(line 	sh_wea year if country == "DOM", color($c_dom))		///
	(line 	sh_wea year if country == "ECU", color($c_ecu))		///
	(line 	sh_wea year if country == "GTM", color($c_gtm))		///
	(line 	sh_wea year if country == "MEX", color($c_mex))		///
	(line 	sh_wea year if country == "PER", color($c_per))		///
	(line 	sh_wea year if country == "VEN", color($c_ven))		///
	/*(line 	sh_wea year if country == "CUB", color($c_cub))*/		///
	, 												///
	$graph_scheme 									///
	ylabel(0(0.2)1, $ylab_opts) 					///
	xlabel(1995(5)2017, $xlab_opts) 				///
	xtitle("Year")									///
	ytitle("LATAM´s billionares per million adults")		///
	legend(order(1 "ARG" 2 "BMU" 3 "BRA"  ///
		4 "CHL" 5 "COL" 6 "BRB" 7 "CYM" 8 "DOM" ///
		9 "ECU" 10 "GTM" 11 "MEX" 12 "PER" 13 "VEN" /*14 "CUB"*/ ))		///
	aspect(.4)
	qui graph export "$figures/forbes_legend.pdf", replace


// share of top 1/f's wealth in adult population
forvalues f = $fractiles {
	qui use `top_1_`f'', clear

	twoway 												///
		(line 	sh_wea year if country == "ARG", color($c_arg))		///
		(line 	sh_wea year if country == "BMU", color($c_bmu))		///
		(line 	sh_wea year if country == "BRA", color($c_bra))		///
		(line 	sh_wea year if country == "CHL", color($c_chl))		///
		(line 	sh_wea year if country == "COL", color($c_col))		///
		(line 	sh_wea year if country == "BRB", color($c_brb))		///
		(line 	sh_wea year if country == "CYM", color($c_cym))		///
		(line 	sh_wea year if country == "DOM", color($c_dom))		///
		(line 	sh_wea year if country == "ECU", color($c_ecu))		///
		(line 	sh_wea year if country == "GTM", color($c_gtm))		///
		(line 	sh_wea year if country == "MEX", color($c_mex))		///
		(line 	sh_wea year if country == "PER", color($c_per))		///
		(line 	sh_wea year if country == "VEN", color($c_ven))		///
		/*(line 	sh_wea year if country == "CUB", color($c_cub))*/		///
		, 												///
		$graph_scheme 									///
		ylabel(0(0.01)0.05, $ylab_opts) 					///
		xlabel(1990(5)2017, $xlab_opts) 				///
		legend(off)										///
		xtitle("Year")									///
		ytitle("wealth share of the 1/`f' fractile")		///
		aspect(.4)
		qui graph export "$figures/forbes_shwea_top_`f'.pdf", replace
}

// prepare data and variables to graph latam vs rest of the world
qui use `forbes_latam', clear
qui gen count = 1
qui gen av_wealth = wealth // auxliary variable
qui collapse (sum) wealth (mean) av_wealth (count) count, ///
	by(latam_c year)
qui reshape wide wealth av_wealth count , i(year) j(latam_c)

qui rename wealth0 nwth_oth 
qui rename count0 n_oth 
qui rename wealth1 nwth_lat
qui rename count1 n_lat	
qui rename av_wealth0 av_nwth_oth
qui rename av_wealth1 av_nwth_lat
	
qui gen sh_latam_n 		= n_lat 		/ n_oth
qui gen sh_latam_w 		= nwth_lat 		/ nwth_oth
qui gen sh_latam_avw 	= av_nwth_lat 	/ av_nwth_oth
qui gen aux 			= 0

// graph
twoway 												///
	(line 	sh_latam_n year)						///
	(line 	sh_latam_w year)						///
	(line 	aux year, color(black%0))			///
	, 												///
	$graph_scheme 									///
	ylabel(0(.02).2, $ylab_opts) 					///
	xlabel(1988(2)2017, $xlab_opts) 				///
	xtitle("Year")									///
	ytitle("Latin America´s billionares share")		///
	legend(order(	1  "% individuals" 2  "% Net worth" 3 ""))		///
	aspect(.4)
	qui graph export "$figures/forbes_shares_latam.pdf", replace
	
twoway 												///
	(line 	sh_latam_avw year, 	yaxis(1))						///
	(line 	av_nwth_lat year, 	yaxis(2))						///
	(line 	av_nwth_oth year, 	yaxis(2))						///
	, 												///
	$graph_scheme 									///
	ylabel(0(0.2)2, $ylab_opts axis(1)) 					///
	ylabel(0(2000)8000, axis(2)) 					///
	xlabel(1988(2)2017, $xlab_opts) 				///
	xtitle("Year")									///
	ytitle("% LATAM's av. net worth",  axis(1))		///
ytitle("Av. net worth (million US dollars)",  axis(2))		///
	legend(order(1  "% LATAM's av. net worth" 2  "Av. LATAM" 3  "Av. RW"))		///
	aspect(.4)
	qui graph export "$figures/forbes_avwealth_latam.pdf", replace
	


