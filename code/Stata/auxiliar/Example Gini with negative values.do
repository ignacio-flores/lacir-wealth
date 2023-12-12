/*
Adjusted Gini to address negative values

Based on:

Raffinetti, E., Siletti, E. & Vernizzi, A. On the Gini coefficient normalization
when attributes with negative values are considered. Stat Methods Appl 24, 
507–521 (2015).

https://link.springer.com/article/10.1007/s10260-014-0293-4

-------------------------------------------------
 Their approach is to keep the original denominator of the Gini but
 replacing the numerator to redefine what 'maximum inequality' looks
 like. 
 
 Maximum inequality: One person having the sum of all negative incomes,
 another one having the sum of all positive income, and N-2 individuals
 with zero income.
 
 Their example:
 a		b		c
-5		-45		-15
-5		0		-10
-5		0		-8
-5		0		-7
-5		0		-5
-5		0		0
-5		0		0
-5		0		0
-5		0		0
45.01	45.01	45.01

Adjusted Gini: 0.555, 1, 0.8346.

*/

capture drop n N
capture drop sumwi totwi
capture drop g1 g2 g3
capture drop denominator
capture drop min_val max_val
capture drop Tplus Tminus
capture drop numerator
capture drop adj_gini 

* Define attribute
local var $var
local weight $weight
***************

* Numerator 

sort `var'
egen totwi = total(`weight') if !missing(`var')
gen sumwi = sum(`weight') if !missing(`var')
gen n = sumwi if !missing(`var')
gen N = totwi if !missing(`var')

gen g1 = 2*n*`var'
gen g2 = N* `var'
gen g3 = `var'

egen numerator = total(`weight'*(g1 - g2 - g3))

drop g1 g2 g3

* Denominador

	gen min_val = `var' if `var' < 0
		replace min_val = 0 if missing(min_val)
	gen max_val = `var' if `var' > 0
		replace max_val = 0 if missing(max_val)

	egen Tplus = total(max_val * `weight') 
	egen Tminus = total(min_val * `weight')
		replace Tminus = abs(Tminus)
		
drop min max

gen denominator = (Tplus + Tminus) / N

* Gini

gen adj_gini = numerator / (N*N*denominator)

drop numerator denominator Tplus Tminus n N