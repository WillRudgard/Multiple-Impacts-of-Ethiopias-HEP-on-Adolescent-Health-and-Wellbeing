*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*---------------------------Covariates - Older cohort--------------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

*------------------------------------------------------------------------------*
// Most covariates are already in the constructed dataset
*------------------------------------------------------------------------------*

/*
Variables already in constructed data covariates include in merging do file 
	
Individual child demographic data : chsex   chethnic  chldrel  chlang agemon  entype agestrtsch
Parent characteristics: dadage  dadlive  momage momlive  dadedu momedu
Household head characteristics: headage  headsex  headedu  headrel cat
Caregiver characteristics:  careage  caresex  carehead carerel  carecantread  caredu
Household characteristics:  wi_new  hq_new  sv_new  cd_new  hhsize  ownlandhse  ownhouse  aniany  region  typesite
*/

* Set working directory:
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"

*------------------------------------------------------------------------------*
// Shock variables
*------------------------------------------------------------------------------*

* Load constructed data to extract round 2,3 and 4 data
use "UKDA-7483-stata\stata\stata11\ethiopia_constructed.dta"  , clear
drop if yc == 1
drop if round == 5

* Death of parent or household member
generate shdthbin = .
replace shdthbin = 0 if shfam1 == 0 & shfam2 == 0 & shfam3  == 0
replace shdthbin = 1 if shfam1 == 1 | shfam2 == 1 | shfam3  == 1 

* Illness of parent or household member
generate shillbin = .
replace shillbin = 0 if shfam4 == 0 & shfam5 == 0 & shfam6  == 0
replace shillbin = 1 if shfam4 == 1 | shfam5 == 1 | shfam6  == 1

* Increase in food prices at round 3 and round 4
generate shfoodbin = shecon13 
 	
* Crop Failure
generate shcropbin = shenv6 

* Drought
generate shdroughtbin = shenv1

* Select variables of interest
keep childid round shdthbin shillbin shfoodbin shcropbin shdroughtbin

* Reshape data
reshape wide shdthbin shillbin shfoodbin shcropbin shdroughtbin, i( childid ) j( round )

* Drop round 1 variables as these are not included in the constructed data.
drop shdthbin1 shillbin1
 
* Save round 2, 3, and 4 data
save "Subset data\ethiopia_oc_hhshocks.dta", replace

* Load round 1 data to fill in information on this round
use "UKDA-5307-stata\stata\stata11\r1_oc\ethiopia\etchildlevel8yrold.dta" , clear

* Generate new variable for school enrollment
generate enrolnew1 = 0 if schnow == 1
recode schwhy (1/3=1) (4=2) (10=3) (5/9 11=4)
replace enrolnew1 = schwhy if schwhy !=.
label define enrolnewlab 0 "In school" 1 "Fees to expensive" 2 "School too far" 3 "Needed at home" 4 "Other"
label values enrolnew1 enrolnewlab 

* Death of family member
rename hhdeath shdthbin1
 
* Illness of family member
rename hhill shillbin1

* Decrease in food availability
*rename hhfood shfood1

* Drop variable labels
label drop hhdeath hhill hhfood 

* Recode 2s to 0s
foreach i in shdthbin1 shillbin1 {
replace `i' = 0 if badevent == 2
recode `i' (2 = 0)
}

* Select variables of interest
keep childid shdthbin1 shillbin1 enrolnew1

* Merge to variables extracted from constructed data
merge 1:1 childid using "Subset data\ethiopia_oc_hhshocks.dta"
drop _merge

* Relabel variables
label define noyes 0 "No" 1 "Yes"
foreach i of num 1/4{
foreach var in shdthbin shillbin shfoodbin shcropbin shdroughtbin {
label values `var'`i' noyes
}
}

* Save final data
save "Subset data\ethiopia_oc_hhshocks.dta", replace

*------------------------------------------------------------------------------*
// Time to school at round 3
*------------------------------------------------------------------------------*

use "UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_childlevel.dta" , replace

* Schooling 
keep CHILDID ENRSCHR3 SCHMINR3 TRNSCHR3 MISSCHR3

rename ( CHILDID ENRSCHR3 SCHMINR3 TRNSCHR3 MISSCHR3 ) ( childid enrschr3 schminr3 trnschr3 misschr3 )

* Save final data
save "Subset data\ethiopia_oc_schoolingr3.dta", replace

*------------------------------------------------------------------------------*
// Distance to nearest government health post at round 3
*------------------------------------------------------------------------------*

use "UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_householdlevel.dta" , replace

* Schooling 
keep childid gochilr3 frcntr3 frpstr3

* Save final data
save "Subset data\ethiopia_oc_healthpostr3.dta", replace

*------------------------------------------------------------------------------*
// Community health care facilities
*------------------------------------------------------------------------------*

* Load health care facility data
use "UKDA-5307-stata\stata\stata11\r1_comm\ethiopia\et_r1_subhealthfacility.dta" , replace

* Keep relevant variables
keep commid facility helid heldis heltme

* Reshape
reshape wide facility heldis heltme , i(commid) j(helid)

* Facility codes:
* 01= Public Hospital *
* 02= Private Hospital *
* 03= Public health post *
* 04= Public health centre *
* 05= Private health centre
* 06= Government dispensary
* 07= Private dispensary
* 08= Private maternity home
* 09= Drug store/ seller
* 10= Family planning clinic *

* Levels for distance:
* 1= <1 KM
* 2= 2-5 KM
* 3= 6-10 KM
* 4= >10 KM

* Levels for time:
* 1= <½ hour
* 2= 1/2-1 hour
* 3= 1-2 hours
* 4= >2 hours

* Keep if variable relates to public health post, publuc health centre, or family planning centre.
keep commid facility1 heldis1 heltme1 facility2 heldis2 heltme2 facility3 heldis3 heltme3 facility4 heldis4 heltme4 facility10 heldis10 heltme10

egen hcfdis1 = rowmin( heldis1 heldis2 heldis3 heldis4 heldis10 )
egen hcfme1 = rowmin( heltme1 heltme2 heltme3 heltme4 heltme10 )

* Fill in dta for the other timepoints
foreach i of num 2/4 {
foreach var in hcfdis hcfcme {
generate `var'`i' = .
}
}

* Merge to child level data to extract clustid
merge 1:1 commid using "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives\UKDA-5307-stata\stata\stata11\r1_comm\ethiopia\et_r1_community_main.dta" 

* Extract clustid from commid
gen clustid = substr( commid , 4 , 2 )
destring clustid , replace

* Select variables of interest
keep clustid commid hcfdis1 hcfme1

* Rename id for merging
rename commid commid1
rename clustid clustid1

* Save data
save "Subset data\ethiopia_oc_commhealth.dta", replace

*------------------------------------------------------------------------------*
// Community schooling facilities
*------------------------------------------------------------------------------*

* Load schooling data
use "UKDA-5307-stata\stata\stata11\r1_comm\ethiopia\et_r1_subschool.dta" , replace

* Keep relevant variables
keep commid scid schname schdis schtme

* Reshape
reshape wide schname schdis schtme , i(commid) j(scid)

* Facility codes:
*01= Pre-school
*02= Private primary *
*03= Government primary *
*04= Private secondary school *
*05= Government secondary school *
*06= Technical college
*07= University
*08= Religious school
*09= Adult literacy centre

* Levels for distance:
* 1= <1 KM
* 2= 2-5 KM
* 3= 6-10 KM
* 4= >10 KM

* Levels for time:
* 1= <½ hour
* 2= 1/2-1 hour
* 3= 1-2 hours
* 4= >2 hours

* Keep if variable relates to public health post, publuc health centre, or family planning centre.
keep commid schname2 schdis2 schtme2 schname3 schdis3 schtme3 schname4 schdis4 schtme4 schname5 schdis5 schtme5

egen scprmdis1 = rowmin( schdis2 schdis3 )
egen scsecdis1 = rowmin( schdis4 schdis5 )

egen scprmme1 = rowmin( schtme2 schtme3 )
egen scsecme1 = rowmin( schtme4 schtme5 )

* Fill in dta for the other timepoints
foreach i of num 2/4 {
foreach var in scprmdis scprmme scsecdis scsecme {
generate `var'`i' = .
}
}

* Merge to child level data to extract clustid
merge 1:1 commid using "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives\UKDA-5307-stata\stata\stata11\r1_comm\ethiopia\et_r1_community_main.dta" 

* Extract clustid from commid
gen clustid = substr( commid , 4 , 2 )
destring clustid , replace

* Select variables of interest
keep clustid commid scprmdis1 scsecdis1 scprmme1 scsecme1

* Rename id for merging
rename commid commid1
rename clustid clustid1

* Save data
save "Subset data\ethiopia_oc_commschool.dta", replace

*--------------------------------------End-------------------------------------*
