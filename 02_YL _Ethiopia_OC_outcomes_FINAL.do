*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*---------------------------Outcomes - Older cohort----------------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

/* 
Here we extract additional outcome variables to be added to the constructed 
data. The constructed dataset is in LONG format. Subsetted data were kept in wide 
format and merged into reshaped constructed data in seperate merging .do file.
Time-variant variables were named to include to survey round at the end.
*/

*------------------------------------------------------------------------------*

* Set working directory:
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"
	
*------------------------------------------------------------------------------*
// Literacy and numeracy
*------------------------------------------------------------------------------*

* Load round 4 data for reading and maths tests
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_chcog\et_r4_occog_olderchild.dta" , replace

* Adapt childid so that data can be merged to other rounds
gen childid="ET"+string(CHILDCODE, "%06.0f")

* Rename variables
rename maths_perco mathscore4
rename lang_perco langscore4

* Extract variables
keep childid mathscore4 langscore4

* Generate equivalent variables in earlier rounds for merging with constructed
* data. These will be empty.
generate mathscore1 = .
generate mathscore2 = .
generate mathscore3 = .
generate langscore1 = .
generate langscore2 = .
generate langscore3 = .

*------education sub dataset 
save "Subset data\ethiopia_oc_literacy_numeracy.dta", replace 

*------------------------------------------------------------------------------*
// Job aspirations, alcohol use, child marriage and early pregnancy
*------------------------------------------------------------------------------*

* Load data
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_ch\et_r4_occh_olderchild.dta" , replace

* Select variables
keep CHILDCODE DINT CHGNDRR4 agemon JOBLKER4 YOUALCR4 MCHALCR4 MRTSTSR4 MTHMARR4 YRMARR4 GGVBRTR4 CURRPRR4

* Adapt childid so that data can be merged to other rounds. 
gen childid = "ET" + string( CHILDCODE , "%06.0f" )

* Generate age variable
gen ageyrs = agemon / 12

*Generate alcohol consumption variable
gen chalcohol4 = .
replace chalcohol4 = 0 if YOUALCR4 == 1
replace chalcohol4 = 0 if YOUALCR4 == 2
replace chalcohol4 = 1 if YOUALCR4 == 6
replace chalcohol4 = 1 if YOUALCR4 == 3 | YOUALCR4 == 4

* Generate age of marriage variable
* First format date of interview
gen dint = date(substr(DINT,1,10), "DMY")
gen dob = mofd(dint) - agemon
format dob %tm
* Convert date of marriage recorded in Ethiopian calendar
label drop MTHMARR4 
* Convert to Gregorian year by adding 7 years if the month of marriage is before 
* Tir or 8 if it is after
replace YRMARR4 = YRMARR4 + 7 if MTHMARR4 < 5
replace YRMARR4 = YRMARR4 + 8 if MTHMARR4 >= 5 
* Convert to Gregorian month
recode MTHMARR4 (1=9) (2=10) (3=11) (4=12) (5=1) (6=2) (7=3) (8=4) (9=5) (10=6) (11=7) (12=8)
gen dmarr = ym(YRMARR4, MTHMARR4)
format dmarr %tm
gen marr_age = (dmarr - dob) / 12

* Generate indicator of No child marriage
gen chmarr4 = 0 if marr_age < ageyrs & marr_age != . 
replace chmarr4 = 1 if marr_age > ageyrs | marr_age >= 18 | marr_age == . 
label var chmarr4 "Child NOT married before 18 years"
label define yesno 0 "No" 1 "Yes"
label values chmarr4 yesno
tab chmarr4 , m
  
* Generate indicator of No early pregnancy - considering both live birth and 
* current pregnancy
* At the time of round 4 3 participants were older than 20 years. None of them 
* had ever given birth or were pregnant
gen chpreg4 = 0 if CHGNDRR4 == 2 & GGVBRTR4 >= 1 | CHGNDRR4 == 2 & CURRPRR4 == 1
replace chpreg4 = 1 if CHGNDRR4 == 1
replace chpreg4 = 1 if CHGNDRR4 == 2 & GGVBRTR4 == 0
label var chpreg4 "Child NOT given birth before 20 years"
label values chpreg4 yesno
tab chpreg4, m

* Rename variable about job aspirations
rename JOBLKER4 chjobasp4
recode chjobasp4 (15 39 46=1) (48=2) (7 19=3) (8 13 22 24 27 36=4) (5=5) (1 14 20 31 38 43 45=6) (4 28 37 40=7) (11 18 25 47=8) (2 3 12 34 42 44 77=9)
label define ISIC 1 "Agriculture" 2 "Industry" 3 "Construction" 4 "Trade, transport, and hotels" 5 "Information and communication" 6 "Business services" 7 "Public admin, education" 8 "Health and social work" 9 "Other services"
label values chjobasp4 ISIC

* Keep variables of interest
keep childid chmarr4 chpreg4 chalcohol4 chjobasp4

* Generate dummies for earlier rounds 
generate chmarr1 =.
generate chmarr2 =.
generate chmarr3 =.

generate chpreg1 =.
generate chpreg2 =.
generate chpreg3 =.

* Ever married + ever given birth sub dataset 
save "Subset data\ethiopia_oc_childmarriage_earlymotherhood.dta", replace

*------------------------------------------------------------------------------*	
// Correct answers to 5 reproductive health statements
*------------------------------------------------------------------------------*		

* Load data
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_chcog\et_r4_occog_olderchild.dta" , replace

* Adapt childid so that data can be merged to other rounds. 
gen CHILDID = "ET" + string( CHILDCODE , "%06.0f" )

* Select relevant data
keep CHILDID SELFR401 SELFR402 SELFR403 SELFR404 SELFR405

* Merge to round 3 data 
merge 1:1 CHILDID using "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives\UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_childlevel.dta"

* Select relevant data
keep CHILDID SELFR401 SELFR402 SELFR403 SELFR404 SELFR405 PRGFRSR3 WSHAFTR3 USECNDR3 LKSHLTR3 HIVSEXR3

* Start by recoding variables to incorrect/correct
label define correct 0 "Incorrect" 1 "Correct"

* Answer is false
foreach var of varlist SELFR401 SELFR402 SELFR404 {
recode `var' ( 1 = 0 ) ( 2 = 1 ) ( 3 = 0 )
label values `var' correct
}

foreach var of varlist PRGFRSR3 WSHAFTR3 LKSHLTR3 {
recode `var' ( 0 = 0 ) ( 1 = 1 ) ( 77 = 0 )
label values `var' correct
}

* Answer is true
foreach var of varlist SELFR403 SELFR405 USECNDR3 HIVSEXR3 {
recode `var' ( 1 = 1 ) ( 2 = 0 ) ( 3 = 0 )
label values `var' correct
}

* Answer is true
foreach var of varlist USECNDR3 HIVSEXR3 {
recode `var' ( 0 = 1 ) ( 1 = 0 ) ( 77 = 0 )
label values `var' correct
}

* Generate score of all correct answers
gen chrephealthall4 =  SELFR401 + SELFR402 + SELFR403 + SELFR404 + SELFR405
gen chrephealthall3 =  PRGFRSR3 + WSHAFTR3 + USECNDR3 + LKSHLTR3 + HIVSEXR3

* Generate indicator for 5/5 correct answers
gen chrephealthbin4 = chrephealthall4 == 5
replace chrephealthbin4 = . if chrephealthall4 == .

gen chrephealthbin3 = chrephealthall3 == 5
replace chrephealthbin3 = . if chrephealthall3 == .

* Generate indicator for 2/2 correct answers on pregnancy related questions
gen chrephealthpreg4 = .
replace chrephealthpreg4 = 1 if SELFR401 == 1 & SELFR403 == 1
replace chrephealthpreg4 = 0 if SELFR401 == 0 | SELFR403 == 0

gen chrephealthpreg3 = .
replace chrephealthpreg3 = 1 if PRGFRSR3 == 1 & WSHAFTR3 == 1
replace chrephealthpreg3 = 0 if PRGFRSR3 == 0 | WSHAFTR3 == 0

* Generate indicator for 3/3 correct answers on STI related questions
gen chrephealthsti4 = .
replace chrephealthsti4 = 1 if SELFR403 == 1 & SELFR404 == 1 & SELFR405 == 1
replace chrephealthsti4 = 0 if SELFR403 == 0 | SELFR404 == 0 | SELFR405 == 0

gen chrephealthsti3 = .
replace chrephealthsti3 = 1 if USECNDR3 == 1 & LKSHLTR3 == 1 & HIVSEXR3 == 1
replace chrephealthsti3 = 0 if USECNDR3 == 0 | LKSHLTR3 == 0 | HIVSEXR3 == 0

* Generate dummies for earlier rounds 
generate chrephealthall1 =.
generate chrephealthall2 =.

generate chrephealthbin1 =.
generate chrephealthbin2 =.

generate chrephealthpreg1 =.
generate chrephealthpreg2 =.

generate chrephealthsti1 =.
generate chrephealthsti2 =.

rename CHILDID childid

keep childid chrephealthall* chrephealthbin* chrephealthpreg* chrephealthsti* SELFR401 SELFR402 SELFR403 SELFR404 SELFR405

save "Subset data\ethiopia_oc_reproductivehealth.dta", replace 

*--------------------------------------End-------------------------------------*
