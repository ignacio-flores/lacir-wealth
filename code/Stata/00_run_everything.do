//general settings 
macro drop _all 
clear all 

//get list of paths
capture cd "~/Dropbox/ForGitHub/lacir-wealth/"

// requieres installing (ssc install): 
// fastgini ineqdecgini egenmore 
// grstyle palettes colrspace ineqdec0 grc1leg 

//list codes 
*******************************************
global do_codes0 " "0a" "0b" "0c" "0d" "  
global do_codes1 " "1a" "1b" " 
global do_codes2 " "2a" "2b" "2c" " 
global do_codes3 " "3a" "3b" "3c" "
global do_codes4 " "4a" "
global do_codes5 " "5b" "
global do_codes6 " "6a" "
*******************************************

//report and save start time 
global run_everything " "ON" "
local start_t "($S_TIME)"
di as result "Started running everything working at `start_t'"

//prepare list of do-files 
forvalues n = 0/6 {

	//get do-files' name 
	foreach docode in ${do_codes`n'} { 
		local do_name : dir "code/Stata/." files "`docode'*.do"
		local do_name = subinstr(`do_name', char(34), "", .)	
		global doname_`docode' `do_name'
		
	}
}

//loop over all files  
forvalues n = 0/6 {
	foreach docode in ${do_codes`n'} {
		
		//run file 
		do Code/Stata/${doname_`docode'}
		
		//record time
		global do_endtime_`docode' " - ended at ($S_TIME)"
		
		//remind plan
		di as result "{hline 70}" 
		di as result "list of files to run, started at `start_t'"
		di as result "{hline 70}"
		forvalues x = 0/6 {
			di as result "Stage nº`x'"
			foreach docode2 in ${do_codes`x'} {
				di as text "  * " "${doname_`docode2'}" _continue
				di as text " ${do_endtime_`docode2'}"
			}
			if `x' == 6 di as result "{hline 70}"	
		}
	}
}

global run_everything " "" "

