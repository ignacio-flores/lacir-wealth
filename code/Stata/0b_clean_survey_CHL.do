
*settings 
clear 
global data "data/surveys"

local years 2007 2011 2014 2017

foreach y of local years{

qui use "$data/CHL/Bases_imputadas/EFH_`y'_arm.dta", clear

// General variables-------------------------------------------------------------

qui gen  weight = factor	
qui gen id_hou  = id

// Main variables---------------------------------------------------------------
qui egen	fin_ass 	= rowtotal(pension stock cash otherfin) 
qui egen 	nfi_ass 	= rowtotal(housing otherestate otherreal auto) 
qui egen 	tot_lia		= rowtotal(debt)
qui egen 	tot_ass		= rowtotal(nfi_ass fin_ass)
qui egen 	net_wth		= rowtotal(tot_ass tot_lia)

// per capita
foreach v in fin_ass nfi_ass tot_lia tot_ass net_wth{
	qui gen `v'_pc = `v' /  numh
}

gen year = `y'

qui keep weight id_hou fin_ass nfi_ass tot_lia tot_ass net_wth *_pc year

// Labels ----------------------------------------------------------------------

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
	cap label var nfi_ass_pc  	"non financial assets (pc)"
	cap label var pen_ass_pc	"pensions assets (pc)"
	cap label var tot_ass_pc	"total assets (pc)"
	cap label var tot_lia_pc	"total liabilities (pc)"
	cap label var net_wth_pc	"net worth assets (pc)"
	
	qui gen ton_lia = tot_lia 
	qui replace ton_lia = 0 if missing(ton_lia)
	qui label var ton_lia "Total liabilities (negative)"

compress
qui save "$data/CHL/output/CHL_`y'.dta", replace

}
