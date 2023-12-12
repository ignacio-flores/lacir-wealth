************************
* Set graphics
 grstyle init
 grstyle set plain, grid
 grstyle set legend 5, nobox inside
 grstyle set color cblind, select(1 2 3 4 5 7 8 9)
 grstyle set symbol O T S D Oh Th Sh Dh X p O
 grstyle set symbolsize large
 grstyle set lpattern solid solid solid solid
 grstyle set compact
************************	

* Top 1% or 10% share:
import delimited "data/DFM/smicrofile_long_grouped.csv", clear

keep if var == "cap_sh"
keep if gr == "t10" | gr == "t1"
keep if step == "nat"
keep if unit == "pch"

bysort step unit var country year: egen value2 = total(value)
keep if gr == "t10"
drop value
rename value2 value

keep country year value
reshape wide value, i(year) j(country) string
egen avg = rowmean(valueARG valueBRA valueCHL valueCOL valueCRI valueECU valueMEX valuePER valueSLV valueURY)
* Label countries:
foreach c of newlist ARG BRA CHL COL CRI ECU MEX PER SLV URY{
	label var value`c' "`c'"
}
label var avg "Average"

tw (connect valueARG valueBRA valueCHL valueCOL valueCRI valueECU valueMEX valuePER valueSLV valueURY year, lcolor(%20...) mcolor(%20...)) (connect avg year), ///
ylabel(0(.1)1, angle(0) format(%12.1f)) legend(pos(1) row(3)) xtitle("") ytitle("Capital income share")

graph export "figures/surveys/capital income/capital_income_top10share.pdf", ///
	replace

