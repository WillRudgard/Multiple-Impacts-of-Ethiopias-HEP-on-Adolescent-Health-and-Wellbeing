*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*--------------------Tabulating descriptive characteristics--------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

*------------------------------------------------------------------------------*
/// Set working directory and load data
*------------------------------------------------------------------------------*

* Working directory
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc"
//cd  "C:\Users\User\Desktop\Young Lives"

* Load the final older cohort long format dataset (obtained from executing the the merging_ do file)
use "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives\Subset data\ethiopia_oc_r1234_long.dta" ,  clear

*------------------------------------------------------------------------------*
/// Recodes
*------------------------------------------------------------------------------*

* Check individual listed as second cycle of primary teaching, their highest 
* grade attained is 6. I therefore assume that they are in grade 7.

* Recode school enrollment to consider anyone that has completed secondary school
replace enrol = 1 if hghgrade == 12 | hghgrade == 13 | hghgrade == 14 | hghgrade == 29

* Generate variable for highest grade obtained at round 4
recode hghgrade (29/30 = 14)

codebook langscore if round == 4 & chsex == 1
codebook langscore if round == 4 & chsex == 2

codebook mathscore if round == 4 & chsex == 1
codebook mathscore if round == 4 & chsex == 2

*------------------------------------------------------------------------------*	
//  Tabulate baseline characteristics overall and by sex
*------------------------------------------------------------------------------*

* Overall
preserve
table1_mc if round == 1, vars( ///
/* Participant characteristics */ chsex cat \ ageyear contn \ stunting cat \ chhprob cat \ chhrel cat \ enrolnew cat \ ///
/* Household characteristics */ typesite cat \ region cat\ hhsize contn \ wlthindex contn \ shillbin cat \ shdthbin cat \ shcropbin cat \ ///
/* Caregiver characteristics */ careage contn \ caresex cat \ caredu cat \ ///
/* Covariates over-follow-up */ agestrtsch contn ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.11 Table Baseline 20210211.xlsx", replace
restore

* By sex
preserve
table1_mc if round == 1, by( chsex ) vars( ///
/* Participant characteristics */ chsex cat \ ageyear contn \ stunting cat \ chhprob cat \ chhrel cat \ enrolnew cat \ ///
/* Household characteristics */ typesite cat \ region cat\ hhsize contn \ wlthindex contn \ shillbin cat \ shdthbin cat \ shcropbin cat \ ///
/* Caregiver characteristics */ careage contn \ caresex cat \ caredu cat \ ///
/* Covariates over-follow-up */ agestrtsch contn ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.13 Table Baseline 20210211.xlsx", replace
restore

*------------------------------------------------------------------------------*	
//  Tabulate time-varying characteristics overall and by sex
*------------------------------------------------------------------------------*

* Overall
preserve 
table1_mc if round == 4, vars( ///
/* Covariates over-follow-up */ shdroughtbinFU cat \ psnpFU cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.12 Table Baseline 20210211.xlsx", replace
restore

* By sex
preserve
table1_mc if round == 4, by( chsex ) vars( ///
/* Covariates over-follow-up */ shdroughtbinFU cat \ psnpFU cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.14 Table Baseline 20210211.xlsx", replace
restore

*------------------------------------------------------------------------------*	
//  Tabulate frequency of HEP receipt overall and by sex
*------------------------------------------------------------------------------*

* Overall
tab hextwelve if round == 4 , m 
tab hexfifteen if round == 4 , m 
* By sex
tab hextwelve chsex if round == 4 , col
tab hexfifteen chsex if round == 4 , col

* Year HEP support began
tab hexstr hexfifteen, m nolab
gen hexfifteenstr = .
replace hexfifteenstr = 1 if hexstr == 2008 | hexstr == 2009 | hexstr == 2010
replace hexfifteenstr = 2 if hexstr == 2003 | hexstr == 2004 | hexstr == 2005 | hexstr == 2006 | hexstr == 2007
replace hexfifteenstr = 0 if hexfifteen == 0
* Overall
tab hexfifteenstr if round == 4 , m
* By sex
tab hexfifteenstr chsex if round == 4 , col chi

* Frequency of HEP support
gen hexfifteenoftr = .
replace hexfifteenoftr = 1 if hexoftr == 12 | hexoftr == 11 | hexoftr == 7 | hexoftr == 6 | hexoftr == 5 | hexoftr == 4
replace hexfifteenoftr = 2 if hexoftr == 10 | hexoftr == 9 | hexoftr == 8 
replace hexfifteenoftr = . if hexoftr == 1 | hexoftr == 3 | hexoftr == 77 | hexoftr == 88
replace hexfifteenoftr = 0 if hexfifteen == 0
* Overall
tab hexfifteenoftr if round == 4 , m
* By sex
tab hexfifteenoftr chsex if round == 4 , col chi

* Satisfaction with HEP support
gen hexfifteenexpr = .
replace hexfifteenexpr = hexexpr
replace hexfifteenexpr = 0 if hexfifteen == 0
* Overall
tab hexfifteenexpr if round == 4 , m
* By sex
tab hexfifteenexpr chsex if round == 4 , col chi

*------------------------------------------------------------------------------*	
//  Tabulate baseline determinants of receiving HEP overall and by sex
*------------------------------------------------------------------------------*

* Overall
preserve
table1_mc if round == 1, by( hexfifteen ) vars( ///
/* Controls */ ///
/* Participant characteristics */ chsex cat \ ageyear contn \ stunting cat \ chhprob cat \ chhrel cat \ enrolnew cat \ ///
/* Household characteristics */ typesite cat \ region cat\ hhsize contn \ wlthindex contn \ shillbin cat \ shdthbin cat \ shcropbin cat \ ///
/* Caregiver characteristics */ careage contn \ caresex cat \ caredu cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.20 Table HEP 20210211.xlsx", replace
restore

* Boys
preserve
table1_mc if round == 1 & chsex == 1, by( hexfifteen ) vars( ///
/* Controls */ ///
/* Participant characteristics */ ageyear contn \ stunting cat \ chhprob cat \ chhrel cat \ enrolnew cat \ ///
/* Household characteristics */ typesite cat \ region cat\ hhsize contn \ wlthindex contn \ shillbin cat \ shdthbin cat \ shcropbin cat \ ///
/* Caregiver characteristics */ careage contn \ caresex cat \ caredu cat \ ///
/* Covariates over-follow-up */ agestrtsch contn ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.21 Table HEP 20210211.xlsx", replace
restore

* Girls
preserve
table1_mc if round == 1 & chsex == 2, by( hexfifteen ) vars( ///
/* Controls */ ///
/* Participant characteristics */ ageyear contn \ stunting cat \ chhprob cat \ chhrel cat \ enrolnew cat \ ///
/* Household characteristics */ typesite cat \ region cat\ hhsize contn \ wlthindex contn \ shillbin cat \ shdthbin cat \ shcropbin cat \ ///
/* Caregiver characteristics */ careage contn \ caresex cat \ caredu cat \ ///
/* Covariates over-follow-up */ agestrtsch contn ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.22 Table HEP 20210211.xlsx", replace
restore

*------------------------------------------------------------------------------*	
//  Tabulate time-varying covariates by HEP
*------------------------------------------------------------------------------*

* By HEP
preserve
table1_mc if round == 4, by( hexfifteen ) vars( ///
/* Covariates over-follow-up */ shdroughtbinFU cat \ shfoodbinFU cat \ psnpFU cat ) onecol missing format( %12.2fc ) percformat( %12.2f ) pdp(6) percsign("") clear
restore

*------------------------------------------------------------------------------*	
//  Tabulate outcomes at round 4 by sex
*------------------------------------------------------------------------------*

// Round 4
preserve
table1_mc if round == 4, by ( chsex ) vars( ///
/* SDG Outcomes */ ///
/* Anthropometric information */ thinness cat \ ///
/* Child Health */ chhealthbin cat \ ///
/* Education */ enrol cat \ langscore contn \ mathscore contn \ ///
/* Employment */ hrsdombin cat \ hrsdom contn \ hrsempbin cat \ hrsemp contn \ ///
/* Gender */ chrephealthpreg cat \ chrephealthsti cat \  ///
/* Alcohol use */ chalcohol cat \ ///
/* Child marriage */ chmarr cat \ chpreg cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.31 Table Outcomes R4 20201025.xlsx", replace
restore

// Round 4
preserve
table1_mc if round == 4 , by ( chsex ) vars( ///
/* Gender */ SELFR401 cat \ SELFR402 cat \ SELFR403 cat \ SELFR404 cat \ SELFR405 cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.31 Table Outcomes SRH R4 20201025.xlsx", replace
restore

foreach i of num 1/4{
preserve
table1_mc if round == 4 & region == `i' , by ( chsex ) vars( ///
/* Gender */ SELFR401 cat \ SELFR402 cat \ SELFR403 cat \ SELFR404 cat \ SELFR405 cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.31 Table Outcomes SRH `i' R4 20201025.xlsx", replace
restore
}

// Rounds 1-4 
preserve
egen new_id = concat( chsex round hexfifteen )
table1_mc , by ( new_id ) vars( ///
/* SDG Outcomes */ ///
/* Anthropometric information */ thinness cat \ ///
/* Child Health */ chhealthbin cat \ ///
/* Education */ enrol cat \ hghgrade contn \ langscore contn \ mathscore contn \ ///
/* Employment */ hrsdombin cat \ hrsdom contn \ hrsempbin cat \ hrsemp contn \ ///
/* Gender */ chrephealthpreg cat \ chrephealthsti cat \ ///
/* Alcohol use */ chalcohol cat \ ///
/* Child marriage */ chmarr cat \ chpreg cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "04_Tables\1.31 Table Outcomes R1-4 20201025.xlsx", replace
restore

*---Correlation matrix for outcome variables by sex
bysort chsex : pwcorr thinness chhealthbin chrephealthpreg chrephealthsti chmarr chpreg chalcohol enrol hrsdombin hrsempbin langscore mathscore if round == 4 

*------------------------------------------------------------------------------*	
//  Sensitivity analysis of household access to school at round 3
*------------------------------------------------------------------------------*

/* School enrolment by receipt of HEP by age fifteen*/
tab enrschr3 hexfifteen if round  == 3 , m col chi
/* No statistically significant difference */

/* Time to school (in minutes)*/
ttest schminr3 if schminr3 >= 0 & enrschr3 == 1 & round == 3 , by( hexfifteen )

/* In the last 12 months have you missed school for one week or more?*/
tab misschr3 hexfifteen if round  == 3 , m col chi

/* Where household usually go with participant if he/she is ill?*/
tab gochilr3 hexfifteen if round ==3 , m col chi 
/* No statistically significant difference */

/* Distance to health centre (in km)*/
ttest frcntr3 if frcntr3 <= 25 & round == 3 , by( hexfifteen )

/* Distance to health post/ clinic (in km)*/
ttest frpstr3 if frpstr3 <= 25 & round == 3 , by( hexfifteen )

*-------------------------------------End--------------------------------------*
