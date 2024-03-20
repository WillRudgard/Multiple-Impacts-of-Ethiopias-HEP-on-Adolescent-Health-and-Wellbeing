*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*-------------------------Merging file - Older Cohort--------------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

* Set working directory:
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"

/*
Identification variables
1. childid: a unique identification was assigned to each Young Lives child at 
baseline. This ID was retained in all the survey waves to track the child. The 
first two characters of the childid are the country initials (ET for Ethiopia) 
while the next two characters is the cluster ID (clustid).
2. clustid: a  Cluster ID was assigned to every sentinental site visited at 
baseline ( a total of 20 sentinental sites)
3. commid: community could either be considered a sentinel site or as a centre 
for creating a sentinel site, depending on the number of eligible households 
residing there. In Round 1 there were 26 communities, which decreased to 24 in 
Round 2 as two communities were merged. In Round 3, the number of communities 
increased to 27 because three of the previous communities were split becoming 
six.
4. Also included are the household head ID (headid), father's ID (dadid), 
mother's ID (momid) and caregiver ID (careid). There is no variable representing 
household id
    
Panel variables
1. round   - identifies the survey round
2. inround - identifies if the child was present in survey round
3. deceased - identifies if the child has died
*/

*------------Run accelerator, outcome, and covariate cleaning files------------*

* This is to ensure that all of the necessary .dta files are saved in the subset
* data file.

* Make sure that all working directories in the above are set accordingly.

* Accelerators
do "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\03_Syntax\01_YL _Ethiopia_OC_accelerators_FINAL.do"

* SDG outcomes
do "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\03_Syntax\02_YL _Ethiopia_OC_outcomes_FINAL.do"

* Covariates
do "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\03_Syntax\03_YL _Ethiopia_OC_covariates_FINAL.do"

*------------------------------------------------------------------------------*

* Load Ethiopia rounds 1 to 5 constructed data
use "UKDA-7483-stata\stata\stata11\ethiopia_constructed.dta" , replace

* Identifying children lost to follow up :
tab inround    // gives total  number of participants lost to follow up
tab round inround  // gives the number of participants lost to follow up at each wave

* Restrict data to older cohort only 
tab yc , m 
keep if yc == 0

* Restrict data to round 1 to 4
tab round , m    
keep if round < 5           

* Rename variables with numbers at the end
rename chrephealth1 chrephealthscale
rename chrephealth2 chrephealthcndm
rename chrephealth3 chrephealthsex
rename chrephealth4 chrephealthserv
rename agegr1 agestrtsch

* Drop unnecessary variables
drop female1860-female61 shcrime1-shother yc

* Convert age variable to years for descriptives
gen ageyear = agemon / 12

* Generate year at 15
gen monthlydint=mofd(dint)
gen dob = monthlydint - agemon
format dob %tm
gen dfifteen = dob + 180 /*months*/
format dfifteen %tm
gen yfifteen = yofd(dofm(dfifteen))
recast int yfifteen
gen dtwelve = dob + 144 /*months*/
format dtwelve %tm
gen ytwelve = yofd(dofm(dtwelve))
recast int ytwelve
gen dnineteen = dob + 228 /*months*/
format dnineteen %tm
gen ynineteen = yofd(dofm(dnineteen))
recast int ynineteen

* Multiply the wealth index by 100
generate wlthindex = wi_new * 100

* Recode child ethinicity
recode chethnic ( 10 = 20 )
label define ethcat 11 "Agew" 12 "Amhara" 13 "Gurage" 14 "Hadiva" 15 "Kambata" 16 "Oromo" 17 "Sidama" 18 "Tigrian" 19 "Wolavta" 20 "Other"
label values chethnic ethcat

* Recode child language
recode chlang ( 1 13 = 20)

* Recode child religion
recode chldrel (2 = 1) (7 = 2) (5 6 15 = 3)
label define religioncat 1 "Muslim" 2 "Orthodox" 3 "Other"
label values chldrel religioncat

* Replace missing data on caregiver sex with data on household head sex. In both 
* cases the household head is female.
replace caresex = headsex if caresex == . 

* Recode region of residence
recode region (3 = 2) (4 = 3) (7 = 4) (14 = 6) 
label define regcat 1 "Tigray" 2 "Amhara" 3 "Oromiya" 4 "SNNP" 5 "Somali" 6 "Addis Ababa City Administration"
label values region regcat

* Recode caregiver education
recode caredu ( 0/4 = 0) ( 5/8 = 1 )( 9/15 = 2 ) ( 28/30 = 2 )
replace caredu = 0 if carecantread == 1
label define schlcat  0 "<=4"  1 "5-8" 2 "9+" 
label values headedu schlcat
label values caredu schlcat

* Recode child health variable to account for differences between reporting options
recode chhealth ( 1 2 3 4 = 0 ) ( 5 = 1 ) , gen(chhealthbin)

* Recode child alcohol
recode chalcohol (0 = 1) (1 = 0)
label var chalcohol "Alcohol no more than 1ce/week"

* Update indicator of low bmi for age for 19 year olds at round 4
recode thinness ( 2/3 = 0 ) ( 0 = 1 )
replace thinness = 0 if bmi < 18.5 & ageyear > 19.0001
replace thinness = 1 if bmi >= 18.5 & ageyear > 19.0001
label var thinness  "Normal BMI for age"
label values thinness noyes

* Label all outcome variables
label var chhealthbin  "Very good health"
label var enrol "Education enrolment"
label values enrol noyes

* Sort data by unique identifier
sort childid

*------------------------------------Reshape-----------------------------------*

* To merge in additional outcome, accelerator, and covariate data it is 
* necessary to reshape the constructed data to wide.

* Reshape the older cohort constructed dataset
reshape wide inround-chhealthbin , i( childid ) j( round ) 

* For merging the unique ID is: childid
drop chalcohol4

*-----------------------------------Outcomes-----------------------------------*

* Merge in literacy and numeracy data
merge 1:1 childid using "Subset data\ethiopia_oc_literacy_numeracy.dta"
drop _merge

* Merge in child marriage and early motherhood data
merge 1:1 childid using "Subset data\ethiopia_oc_childmarriage_earlymotherhood.dta"   
drop _merge	

* Merge in correct answers to 5 reproductive health statements 
merge 1:1 childid using "Subset data\ethiopia_oc_reproductivehealth.dta"
drop _merge

*----------------------------------Covariates----------------------------------*

* Merge time to school at round 3 variables 
merge 1:1 childid using "Subset data\ethiopia_oc_schoolingr3.dta"
drop _merge

* Merge distance to healthcare facility at round 3 variables 
merge 1:1 childid using "Subset data\ethiopia_oc_healthpostr3.dta"
drop _merge

* Merge household shock variables
merge 1:1 childid using "Subset data\ethiopia_oc_hhshocks.dta"
drop _merge

* Merge community health facility 
merge m:1 commid1 using "Subset data\ethiopia_oc_commhealth.dta"
drop if _merge == 2
drop _merge

* Merge community schooling
merge m:1 commid1 using "Subset data\ethiopia_oc_commschool.dta"
drop if _merge == 2
drop _merge

*-----------------------------Constructed outcomes-----------------------------*

* Hours spent on domestic tasks and caring
label define hdom 0 ">=3 hours"  1 "<3hours"
forvalues i = 1/4{
gen hrsdom`i'= hchore`i' + hcare`i' 
gen hrsdombin`i' = .
replace hrsdombin`i' = 0 if hrsdom`i' >= 3
replace hrsdombin`i' = 1 if hrsdom`i' < 3
label values hrsdombin`i' hdom
}

* 3 hours of household chores is associated with worse maths grades: 
* https://www.younglives.org.uk/sites/www.younglives.org.uk/files/Child%20Work%20and%20Academic%20Achievement_Cuesta.pdf

* Hours spent in paid activities
label define hcat 0 "<=4 hours"  1 ">4 hours" 
forvalues i = 1/4{
gen hrsemp`i' = hwork`i' + htask`i'
gen hrsempbin`i' = .
replace hrsempbin`i' = 0 if hrsemp`i' <= 4
replace hrsempbin`i' = 1 if hrsemp`i' > 4
label values hrsempbin`i' hcat
}

* 4 hours of paid activities is used in a previous analysis focusing on child work 
* https://www.younglives.org.uk/sites/www.younglives.org.uk/files/Child-Work-in-East-Africa-Chapter2.pdf

*-----------------------------Additional covariates----------------------------*

* Illness of parent or household member
gen shillbinFU4 = .
replace shillbinFU4 = 0 if shillbin2 == 0 & shillbin3 == 0 & shillbin4 == 0
replace shillbinFU4 = 1 if shillbin2 == 1 | shillbin3 == 1 | shillbin4 == 1

* Death of parent or household member
gen shdthbinFU4 = .
replace shdthbinFU4 = 0 if shdthbin2 == 0 & shdthbin3 == 0 & shdthbin4 == 0
replace shdthbinFU4 = 1 if shdthbin2 == 1 | shdthbin3 == 1 | shdthbin4 == 1

* Increase in food prices from round 3 onwards
gen shfoodbinFU4 = .
replace shfoodbinFU4 = 0 if shfoodbin3 == 0 & shfoodbin4 == 0
replace shfoodbinFU4 = 1 if shfoodbin3 == 1 | shfoodbin4 == 1
 	
* Crop failure
gen shcropbinFU4 = .
replace shcropbinFU4 = 0 if shcropbin2 == 0 & shcropbin3 == 0 & shcropbin4 == 0
replace shcropbinFU4 = 1 if shcropbin2 == 1 | shcropbin3 == 1 | shcropbin4 == 1

* Drought
gen shdroughtbinFU4 = .
replace shdroughtbinFU4 = 0 if shdroughtbin2 == 0 & shdroughtbin3 == 0 & shdroughtbin4 == 0
replace shdroughtbinFU4 = 1 if shdroughtbin2 == 1 | shdroughtbin3 == 1 | shdroughtbin4 == 1

*------------------------------Social programmes-------------------------------*

* Merge social programs 
merge 1:1 childid using "Subset data\ethiopia_oc_supportprograms.dta"
drop _merge 

* Generate indicator of ever received HEP at round 2 or round 3 based on recall at round 4
gen hexfifteen4 = .
replace hexfifteen4 = 0 if hexben4 == 0 /*Never received*/
replace hexfifteen4 = 0 if hexben4 == 1 & hexstr4 > yfifteen1 /*Began receiving after the year in which the participant turned 15*/
replace hexfifteen4 = 1 if hexben4 == 1 & hexstr4 <= yfifteen1 /*Began receiving before or during the year in which the participant turned 15*/
replace hexfifteen4 = . if hexben4 == 1 & hexstr4 ==.

gen hextwelve4 = .
replace hextwelve4 = 0 if hexben4 == 0 /*Never received*/
replace hextwelve4 = 0 if hexben4 == 1 & hexstr4 > ytwelve1 /*Began receiving after the year in which the participant turned 12*/
replace hextwelve4 = 1 if hexben4 == 1 & hexstr4 <= ytwelve1 /*Began receiving before or during the year in which the participant turned 12*/
replace hextwelve4 = . if hexben4 == 1 & hexstr4 ==.

gen hexnineteen4 = .
replace hexnineteen4 = 0 if hexben4 == 0 /*Never received*/
replace hexnineteen4 = 0 if hexben4 == 1 & hexstr4 > ynineteen1 /*Began receiving after the year in which the participant turned 19*/
replace hexnineteen4 = 1 if hexben4 == 1 & hexstr4 <= ynineteen1 /*Began receiving before or during the year in which the participant turned 19*/
replace hexnineteen4 = . if hexben4 == 1 & hexstr4 ==.

foreach i of num 1/3{
generate hextwelve`i' = hextwelve4
generate hexfifteen`i' = hexfifteen4
generate hexnineteen`i' = hexnineteen4
}

* Generate indicator for ever received PSNP at round 2 or round 3
gen psnpFU4 = .
replace psnpFU4 = 0 if  psnp2 == 0 & psnp3 == 0 & psnp4 == 0
replace psnpFU4 = 1 if  psnp2 == 1 | psnp3 == 1 | psnp4 == 1

* Order all variables in sequential order after childid
order _all , seq
order childid

* Drop unecessary variables
drop act06 actr306

* Save final data
save "Subset data\ethiopia_oc_final.dta" , replace

*--------------------------------------End-------------------------------------*
