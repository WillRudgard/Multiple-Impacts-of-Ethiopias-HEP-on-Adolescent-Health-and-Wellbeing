*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*-----------------------------Statistical analysis-----------------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

*------------------------------------------------------------------------------*
/// Set working directory
*------------------------------------------------------------------------------*

cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"
//cd  "C:\Users\User\Desktop\Young Lives"

* Load the final older cohort wide format dataset (obtained from executing the the merging_ do file)
use "Subset data\ethiopia_oc_r1234_wide.dta",  clear

* Change font for graphs to Times New Roman
* graph set window fontface "Times New Roman"

* Recode school enrollment variable 
* to consider anyone that has completed secondary school
replace enrol4 = 1 if hghgrade4 == 12 | hghgrade4 == 13 | hghgrade4 == 14 | hghgrade4 == 29

* Generate new commid for robust standard errors
replace commid1 = substr(commid1, 4, 2)
destring commid1, replace

* Generate variable for duration of follow-up 
generate fu = (dint4 - dint1) / 365.2425
summ fu

*------------------------------------------------------------------------------*
/// Estimate propensity score for binary treatment scenario
*------------------------------------------------------------------------------*

* Estimate PS using logistic regression model
forvalues i = 1/2{
logistic hexfifteen4 ///
/* Adolescent characteristics: */ c.agemon1 i.stunting1 i.chhprob1 i.chhrel1 i.enrolnew1 i.typesite1 i.region1 ///
/* Household characteristics: */ c.hhsize1 c.wlthindex1 ///
/* Caregiver characteristics: */ c.careage1 i.caredu1 /// 
if chsex1 == `i'
mat r=r(table)
matrix beta = r["b",....]'
matrix ll = r["ll",....]'
matrix ul = r["ul",....]'
matrix p = r["pvalue",....]'
matrix reg`i' = (beta, ll, ul, p)
* Estimate Area Under the Curve
lroc, nograph
* An AUC of 0.5 suggests no discrimination (i.e., ability to diagnose patients 
* with and without the disease or condition based on the test), 0.7 to 0.8 is 
* considered acceptable, 0.8 to 0.9 is considered excellent, and more than 0.9 
* is considered outstanding
* Check goodness of fit
estat gof, group(10) table
* The test is non-significant suggesting the model fits the data well.
* Predict propensity to receive cash or food for work program
predict propensity`i' if chsex1 == `i'
* Look at distribution of propensity scores. 
*graph tw kdensity propensity`i' if hexfifteen4 == 0 || ///
*		 kdensity propensity`i' if hexfifteen4 == 1
* Estimate Inverse Probability of Treatment Weight (IPTW)
gen ipt_wt`i' = cond(hexfifteen4, 1/propensity`i', 1/(1-propensity`i')) if chsex1 == `i'
}

* Run histograms for IPTWs
hist ipt_wt1
hist ipt_wt2

* Return matrices of regression coefficients for boys and girls.
matrix list reg1
matrix list reg2

* Generate single indicator of propensity score.
gen ipt_wt = ipt_wt1
replace ipt_wt = ipt_wt2 if ipt_wt1 == .

* Check covariate balance
forvalues i = 1/2{
quietly xi: pbalchk hexfifteen4 ///
/* Adolescent characteristics: */ agemon1 i.stunting1 i.chhprob1 i.enrolnew1 i.typesite1 i.region1 ///
/* Household characteristics: */ hhsize1 wlthindex1 ///
/* Caregiver characteristics: */ careage1 i.caredu1 ///
if chsex1 == `i', wt(ipt_wt)
* Before adjustment
matrix unadj = r(usmeandiff)'
* After adjustment
matrix adj = r(smeandiff)'
matrix both`i' = (unadj, adj)
matrix list both`i'
}

* Generate variable labels
do "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\03_Syntax\MISC_YL_Ethiopia_OC_labels_for_Graph.do"

* Using teffects approach
forvalues i = 1/2{
teffects ipw (chhealthbin4) ///
(hexfifteen4 c.wlthindex1 i.typesite1 i.region1 i.caredu1 c.agemon1 c.hhsize1 ///
i.enrolnew1 i.stunting1 i.chhprob1 i.chhrel1 c.careage1, logit) if chsex1 == `i', pomeans
teffects overlap, ptl(1)
tebalance summarize
mat M`i' = r(table)
mat MF`i' = M`i'[1..19,1..2]
}

* Return unadjusted and adjusted standardised differences for boys and girls
matrix list MF1
matrix list MF2

/// Check balance of time-varying covariates over follow-up
forvalues i = 1/2 {
pbalchk hexfifteen4 ///
agestrtsch1 psnpFU4 shdroughtbinFU4 if chsex1 == `i', wt(ipt_wt)
* Before adjustment
matrix unadj = r(usmeandiff)'
* After adjustment
matrix adj = r(smeandiff)'
matrix M`i'FU = (unadj, adj)
matrix list M`i'FU
}

* Join together all covariates
matrix COVBAll = (MF1\ M1FU)
matrix COVGAll = (MF2\ M2FU)

* Plot balance graphs together
coefplot (matrix(COVBAll[,1]), label("Before adjustment") offset(0) color(red%60)) ///
		 (matrix(COVBAll[,2]), label("After adjustment") offset(0) color(green%60)), bylabel("Boys") || ///
		 (matrix(COVGAll[,1]), label("Before adjustment") offset(0) color(red%60)) ///
		 (matrix(COVGAll[,2]), label("After adjustment") offset(0) color(green%60)), bylabel("Girls") ||, ///
		 noci ///
xlabel(-0.8(0.2)0.6, labsize(small)) xline(0, lwidth(thin) lcolor(black)) xline(-0.1 0.1, lpattern(dash) lwidth(thin) lcolor(black)) xtitle("Standardised difference", size(small)) ///
ylabel(, labsize(small)) ///
title("`v'", margin(b+2.5)) ///
legend(size(small) col(4)) ///
grid(none) graphregion(fcolor(white) color(white) margin(zero)) bgcolor(white) plotregion(color(white))


*------------------------------------------------------------------------------*
/// UNIVARIABLE LOGISTIC regression models
*------------------------------------------------------------------------------*

* BOYS
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chalcohol4 enrol4 hrsdombin4 hrsempbin4{ 
logit `y' i.hexfifteen4 if chsex1 == 1, or
lincom _b[1.hexfifteen4], or
matrix UNIB`y' = (r(estimate), r(lb), r(ub), r(p))
}

*Girls
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 enrol4 hrsdombin4 hrsempbin4 chmarr4 chpreg4 { 
logit `y' i.hexfifteen4 if chsex1 == 2, or
lincom _b[1.hexfifteen4], or
matrix UNIG`y' = (r(estimate), r(lb), r(ub), r(p))
}

* Generate table of OR
matrix UNIBAll = (UNIBthinness4, UNIBchhealthbin4, UNIBchrephealthpreg4, UNIBchrephealthsti4, UNIBchalcohol4, UNIBenrol4, UNIBhrsdombin4 , UNIBhrsempbin4)
matrix list UNIBAll
matrix UNIGAll = (UNIGthinness4, UNIGchhealthbin4, UNIGchrephealthpreg4, UNIGchrephealthsti4, UNIGchmarr4, UNIGchpreg4, UNIGenrol4, UNIGhrsdombin4 , UNIGhrsempbin4)
matrix list UNIGAll

* BOYS & GIRLS
foreach y in hrsemp4 hrsdom4 langscore4 mathscore4 {
quietly regress `y' i.hexfifteen4 if chsex1 == 1
lincom _b[1.hexfifteen4]  // coeff for boys
matrix UNIB`y' = (r(estimate), r(lb), r(ub), r(p))
quietly regress `y' i.hexfifteen4 if chsex1 == 2
lincom _b[1.hexfifteen4] // coeff for girls
matrix UNIG`y' = (r(estimate), r(lb), r(ub), r(p))
}

* Generate table of betas 
matrix UNIBBAll = (UNIBlangscore4 , UNIBmathscore4)
matrix UNIGBAll = (UNIGlangscore4 , UNIGmathscore4)
matrix UNIBALL = (UNIBBAll \ UNIGBAll)
matrix list UNIBALL

*------------------------------------------------------------------------------*
/// MULTIVARIABLE LOGISTIC regression models at round 4
*------------------------------------------------------------------------------*

* BOYS
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chalcohol4 enrol4 hrsdombin4 hrsempbin4{  
logit `y' i.hexfifteen4 i.shdroughtbinFU4 [pw=ipt_wt] if chsex1 == 1, or
lincom _b[1.hexfifteen4], or
matrix B`y' = (r(estimate), r(lb), r(ub), r(p))
margins i.hexfifteen4, post
* HEP = NO in boys
quietly lincom _b[0bn.hexfifteen4]
matrix B`y'1 = (r(estimate), r(lb), r(ub), r(p))
* HEP = YES in boys
quietly lincom _b[1.hexfifteen4]
matrix B`y'2 = (r(estimate), r(lb), r(ub), r(p))
* Difference in boys
quietly lincom _b[1.hexfifteen4] - _b[0bn.hexfifteen4]
matrix B`y'Dif = (r(estimate), r(lb), r(ub), r(p))
matrix B`y'All = (B`y'1 \ B`y'2 \ B`y'Dif)
}

* GIRLS
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chmarr4 chpreg4 enrol4 hrsdombin4 hrsempbin4 { 
logit `y' i.hexfifteen4 i.shdroughtbinFU4 [pw=ipt_wt] if chsex1 == 2, or
lincom _b[1.hexfifteen4], or
matrix G`y' = (r(estimate), r(lb), r(ub), r(p))
margins hexfifteen4, post
* HEP = NO in girls
quietly lincom _b[0bn.hexfifteen4]
matrix G`y'1 = (r(estimate), r(lb), r(ub), r(p))
* HEP = YES in girls
quietly lincom _b[1.hexfifteen4]
matrix G`y'2 = (r(estimate), r(lb), r(ub), r(p))
* Difference in girls
quietly lincom _b[1.hexfifteen4] - _b[0bn.hexfifteen4]
matrix G`y'Dif = (r(estimate), r(lb), r(ub), r(p))
matrix G`y'All = (G`y'1 \ G`y'2 \ G`y'Dif)
}

* Check outcome regression analysis using teffects command (limitation is that one
* can't include additional covariates in the outcome regression using this command)
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chmarr4 chpreg4 chalcohol4 enrol4 hrsdombin4 hrsempbin4 langscore4 mathscore4{ 
forvalues i = 1/2{
teffects ipw (`y') ///
(hexfifteen4 c.wlthindex1 i.typesite1 i.region1 i.caredu1 c.agemon1 c.hhsize1 ///
i.enrolnew1 i.stunting1 i.chhprob1 i.chhrel1 c.careage1, mlogit) if chsex1 == `i', pomeans
contrast r.hexfifteen4
}
}

*------------------------------------------------------------------------------*
/// MULTIVARIABLE OLS regression models
*------------------------------------------------------------------------------*

* BOYS
foreach y in langscore4 mathscore4 {
regress `y' i.hexfifteen4 i.shdroughtbinFU4 [pw=ipt_wt] if chsex1 == 1
lincom _b[1.hexfifteen4]  
matrix B`y' = (r(estimate), r(lb), r(ub), r(p))
margins hexfifteen4, post
* HEP = NO in boys
quietly lincom _b[0bn.hexfifteen4]
matrix B`y'1 = (r(estimate), r(lb), r(ub), r(p))
* HEP = YES in boys
quietly lincom _b[1.hexfifteen4]
matrix B`y'2 = (r(estimate), r(lb), r(ub), r(p))
* Difference in boys
quietly lincom _b[1.hexfifteen4] - _b[0bn.hexfifteen4]
matrix B`y'Dif = (r(estimate), r(lb), r(ub), r(p))
matrix B`y'All = (B`y'1 \ B`y'2 \ B`y'Dif)
}

* GIRLS
foreach y in langscore4 mathscore4 {
regress `y' i.hexfifteen4 i.shdroughtbinFU4 [pw=ipt_wt] if chsex1 == 2
lincom _b[1.hexfifteen4]  
matrix G`y' = (r(estimate), r(lb), r(ub), r(p))
margins hexfifteen4, post
* HEP = NO in girls
quietly lincom _b[0bn.hexfifteen4]
matrix G`y'1 = (r(estimate), r(lb), r(ub), r(p))
* HEP = YES in girls
quietly lincom _b[1.hexfifteen4]
matrix G`y'2 = (r(estimate), r(lb), r(ub), r(p))
* Difference in girls
quietly lincom _b[1.hexfifteen4] - _b[0bn.hexfifteen4]
matrix G`y'Dif = (r(estimate), r(lb), r(ub), r(p))
matrix G`y'All = (G`y'1 \ G`y'2 \ G`y'Dif)
}

* Generate table of ORs and betas
matrix BAll = (Bthinness4, Bchhealthbin4, Bchrephealthpreg4, Bchrephealthsti4, Bchalcohol4, Benrol4, Bhrsdombin4, Bhrsempbin4, Blangscore4 , Bmathscore4)
matrix list BAll
matrix GAll = (Gthinness4, Gchhealthbin4, Gchrephealthpreg4, Gchrephealthsti4, Gchmarr4, Gchpreg4, Genrol4, Ghrsdombin4, Ghrsempbin4, Glangscore4 , Gmathscore4)
matrix list GAll

* Generate table of predicted probabilities
matrix BPredAll = (Bthinness4All, Bchhealthbin4All, Bchrephealthpreg4All, Bchrephealthsti4All, Bchalcohol4All, Benrol4All, Bhrsdombin4All, Bhrsempbin4All, Blangscore4All, Bmathscore4All)
matrix list BPredAll
matrix GPredAll = (Gthinness4All, Gchhealthbin4All, Gchrephealthpreg4All, Gchrephealthsti4All, Gchmarr4All, Gchpreg4All, Genrol4All, Ghrsdombin4All, Ghrsempbin4All, Glangscore4All, Gmathscore4All)
matrix list GPredAll

*------------------------------------------------------------------------------*
/// Estimate propensity score for multivalue treatment scenario
*------------------------------------------------------------------------------*

* Generate multivalued treatment related to when family was first visited by HEWs
tab hexstr4 hexfifteen4, m nolab
gen hexfifteenstr4 = .
replace hexfifteenstr4 = 1 if hexstr4 == 2007 | hexstr4 == 2008 | hexstr4 == 2009 | hexstr4 == 2010
replace hexfifteenstr4 = 2 if hexstr4 == 2003 | hexstr4 == 2004 | hexstr4 == 2005 | hexstr4 == 2006
replace hexfifteenstr4 = 0 if hexfifteen4 == 0
tab hexfifteenstr4 chsex1, m

* Generate multivalued treatment related to frequency of vists
tab hexoftr4
gen hexfifteenoftr4 = .
replace hexfifteenoftr4 = 1 if hexoftr4 == 12 | hexoftr4 == 11 | hexoftr4 == 8 | hexoftr4 == 7 | hexoftr4 == 6 | hexoftr4 == 5 | hexoftr4 == 4
replace hexfifteenoftr4 = 2 if hexoftr4 == 10 | hexoftr4 == 9 
replace hexfifteenoftr4 = . if hexoftr4 == 1 | hexoftr4 == 3 | hexoftr4 == 77 | hexoftr4 == 88
replace hexfifteenoftr4 = 0 if hexfifteen4 == 0

* Estimate generalised propensity score using multinomial regression
forvalues i = 1/2{
mlogit hexfifteenstr4 ///
/* Adolescent characteristics: */ c.agemon1 i.stunting1 i.chhprob1 i.chhrel1 i.enrolnew1 i.typesite1 i.region1 ///
/* Household characteristics: */ c.hhsize1 c.wlthindex1 ///
/* Caregiver characteristics: */ c.careage1 i.caredu1 /// 
if chsex1 == `i', base(0) rrr
predict propensitymulti`i'0 propensitymulti`i'1 propensitymulti`i'2
gen iptm_wt`i' = 1/propensitymulti`i'0 if hexfifteenstr4 == 0 & chsex1 == `i'
replace iptm_wt`i' = 1/propensitymulti`i'1 if hexfifteenstr4 == 1 & chsex1 == `i'
replace iptm_wt`i' = 1/propensitymulti`i'2 if hexfifteenstr4 == 2 & chsex1 == `i'
}

* MULTIVARIABLE LOGISTIC regression models 
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chalcohol4 enrol4 hrsdombin4 hrsempbin4{
forvalues i = 1/2{ 
logit `y' i.hexfifteenstr4 i.shdroughtbinFU4 [pw=iptm_wt`i'] if chsex1 == `i', or
margins i.hexfifteenstr4 if chsex1 == `i', coeflegend post
* HEP = No
quietly lincom _b[0bn.hexfifteenstr4]
matrix P`i'`y'1 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 4-12 months
quietly lincom _b[1.hexfifteenstr4]
matrix P`i'`y'2 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 1/2 months
quietly lincom _b[2.hexfifteenstr4]
matrix P`i'`y'3 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[1.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P`i'`y'Dif1 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[2.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P`i'`y'Dif2 = (r(estimate)\ r(lb)\ r(ub))
matrix P`i'`y'All = (P`i'`y'1, P`i'`y'2, P`i'`y'3, P`i'`y'Dif1, P`i'`y'Dif2)
}
}

foreach y in chmarr4 chpreg4{
logit `y' i.hexfifteenstr4 i.shdroughtbinFU4 [pw=iptm_wt2] if chsex1 == 2, or
margins i.hexfifteenstr4 if chsex1 == 2, coeflegend post
* HEP = No
quietly lincom _b[0bn.hexfifteenstr4]
matrix P2`y'1 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 4-12 months
quietly lincom _b[1.hexfifteenstr4]
matrix P2`y'2 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 1/2 months
quietly lincom _b[2.hexfifteenstr4]
matrix P2`y'3 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[1.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P2`y'Dif1 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[2.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P2`y'Dif2 = (r(estimate)\ r(lb)\ r(ub))
matrix P2`y'All = (P2`y'1, P2`y'2, P2`y'3, P2`y'Dif1, P2`y'Dif2)
}

* MULTIVARIABLE OLS regression models 
foreach y in langscore4 mathscore4{ 
forvalues i = 1/2{
regress `y' i.hexfifteenstr4 i.shdroughtbinFU4 [pw=iptm_wt`i'] if chsex1 == `i'
margins i.hexfifteenstr4 if chsex1 == `i', coeflegend post
* HEP = No
quietly lincom _b[0bn.hexfifteenstr4]
matrix P`i'`y'1 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 4-12 months
quietly lincom _b[1.hexfifteenstr4]
matrix P`i'`y'2 = (r(estimate)\ r(lb)\ r(ub))
* HEP = Every 1/2 months
quietly lincom _b[2.hexfifteenstr4]
matrix P`i'`y'3 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[1.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P`i'`y'Dif1 = (r(estimate)\ r(lb)\ r(ub))
* Difference No vs. Every 4-12 months
quietly lincom _b[2.hexfifteenstr4] - _b[0bn.hexfifteenstr4]
matrix P`i'`y'Dif2 = (r(estimate)\ r(lb)\ r(ub))
matrix P`i'`y'All = (P`i'`y'1, P`i'`y'2, P`i'`y'3, P`i'`y'Dif1, P`i'`y'Dif2)
}
}

mat PB = P1thinness4All, P1chhealthbin4All, P1chrephealthpreg4All, P1chrephealthsti4All, P1chalcohol4All, P1enrol4All, P1hrsdombin4All, P1hrsempbin4All, P1langscore4All, P1mathscore4All
mat list PB
mat PG = P2thinness4All, P2chhealthbin4All, P2chrephealthpreg4All, P2chrephealthsti4All, P2chmarr4All, P2chpreg4All, P2chalcohol4All, P2enrol4All, P2hrsdombin4All, P2hrsempbin4All, P2langscore4All, P2mathscore4All
mat list PG

* Outcome regression analysis using teffects
foreach y in thinness4 chhealthbin4 chrephealthpreg4 chrephealthsti4 chmarr4 chpreg4 chalcohol4 enrol4 hrsdombin4 hrsempbin4 langscore4 mathscore4{ 
forvalues i = 1/2{
teffects ipw (`y') ///
(hexfifteenoftr4 c.wlthindex1 i.typesite1 i.region1 i.caredu1 c.agemon1 c.hhsize1 ///
i.enrolnew1 i.stunting1 i.chhprob1 i.chhrel1 c.careage1, mlogit) if chsex1 == `i', pomeans
mat PO`i'`y' = r(table)
mat PO`i'`y' = (PO`i'`y'[1,1..3]\ PO`i'`y'[5,1..3]\ PO`i'`y'[6,1..3])
contrast r.hexfifteenoftr4
mat ATE`i'`y' = r(table)
mat ATE`i'`y' = (ATE`i'`y'[1,1..2]\ ATE`i'`y'[5,1..2]\ ATE`i'`y'[6,1..2])
mat POATE`i'`y' = (PO`i'`y', ATE`i'`y')
}
}

mat DOSEB = POATE1thinness4, POATE1chhealthbin4, POATE1chrephealthpreg4, POATE1chrephealthsti4, POATE1chmarr4, POATE1chpreg4, POATE1chalcohol4, POATE1enrol4, POATE1hrsdombin4, POATE1hrsempbin4, POATE1langscore4, POATE1mathscore4
mat DOSEG = POATE2thinness4, POATE2chhealthbin4, POATE2chrephealthpreg4, POATE2chrephealthsti4, POATE2chmarr4, POATE2chpreg4, POATE2chalcohol4, POATE2enrol4, POATE2hrsdombin4, POATE2hrsempbin4, POATE2langscore4, POATE2mathscore4
mat DOSEALL = DOSEB \ DOSEG
mat list DOSEALL

*------------------------------------MISC--------------------------------------*

* Rename outcome variables for reshaping data from wide to long (For now, I just use three outcomes).
local outcomes "thinness4" "chhealthbin4" "enrol4" "hrsdombin4" "hrsempbin4" "chrephealthpreg4" "chrephealthsti4" "chalcohol4" "chmarr4" "chpreg4"
forvalues n = 1/10{
local var : word `n' of "`outcomes'"
di "`var'"
gen sdg_i`n' = `var'
tab sdg_i`n', m
}

* Reshape data from wide to long so that each individual i has k rows 
* corresponding to outcome j1 to jk.
generate id = _n
reshape long sdg_i, i(id) j(outcome)

* Define a local with outcomes of interest:
local outcomes "thinness4" "chhealthbin4" "enrol4" "hrsdombin4" "hrsempbin4" "chrephealthpreg4" "chrephealthsti4" "chalcohol4" "chmarr4" "chpreg4"
* Generate binary indicators of outcomes j1 to jk in long data
* REMEMBER locals must be executed at the same time as loops that use them.
forvalues ny = 1/10{
local vary : word `ny' of "`outcomes'"
replace `vary' = 1 if outcome == `ny'
replace `vary' = 0 if outcome != `ny' & `vary' != .
gen hexfifteen4x`vary' = hexfifteen4 * `vary'
gen shdroughtbinFU4x`vary' = shdroughtbinFU4 * `vary'
}

* xtset data
xtset id outcome

* BOYS
local outcomes "thinness4" "chhealthbin4" "enrol4" "hrsdombin4" "hrsempbin4" "chrephealthpreg4" "chrephealthsti4" "chalcohol4" 
forvalues i = 1/10 {
xtgee sdg_i ///
/*Hypothesised accelerators*/ hexfifteen4xthinness4 hexfifteen4xchhealthbin4 hexfifteen4xenrol4 hexfifteen4xhrsdombin4 hexfifteen4xhrsempbin4 hexfifteen4xchrephealthpreg4 hexfifteen4xchrephealthsti4 hexfifteen4xchalcohol4 ///
/*Drought*/ shdroughtbinFU4xthinness4 shdroughtbinFU4xchhealthbin4 shdroughtbinFU4xenrol4 shdroughtbinFU4xhrsdombin4 shdroughtbinFU4xhrsempbin4 shdroughtbinFU4xchrephealthpreg4 shdroughtbinFU4xchrephealthsti4 shdroughtbinFU4xchalcohol4 ///
i.outcome [pw=ipt_wt] if chsex1 == 1, family(binomial) link(logit) vce(robust) eform corr(unstructured)
}

* GIRLS
local outcomes "thinness4" "chhealthbin4" "enrol4" "hrsdombin4" "hrsempbin4" "chrephealthpreg4" "chrephealthsti4" "chalcohol4" "chmarr4" "chpreg4"
forvalues i = 1/10 {
xtgee sdg_i ///
/*Hypothesised accelerators*/ hexfifteen4xthinness4 hexfifteen4xchhealthbin4 hexfifteen4xenrol4 hexfifteen4xhrsdombin4 hexfifteen4xhrsempbin4 hexfifteen4xchrephealthpreg4 hexfifteen4xchrephealthsti4 hexfifteen4xchalcohol4 hexfifteen4xchmarr4 hexfifteen4xchpreg4 ///
/*Drought*/ shdroughtbinFU4xthinness4 shdroughtbinFU4xchhealthbin4 shdroughtbinFU4xenrol4 shdroughtbinFU4xhrsdombin4 shdroughtbinFU4xhrsempbin4 shdroughtbinFU4xchrephealthpreg4 shdroughtbinFU4xchrephealthsti4 shdroughtbinFU4xchalcohol4 ///
i.outcome [pw=ipt_wt] if chsex1 == 2, family(binomial) link(logit) vce(robust) eform corr(unstructured)
local var : word `i' of "`outcomes'"
margins if outcome == `i', at(hexfifteen4x`var' = (0 1)) post
lincom _b[2._at] - _b[1bn._at]
}

*-------------------------------------End--------------------------------------*
