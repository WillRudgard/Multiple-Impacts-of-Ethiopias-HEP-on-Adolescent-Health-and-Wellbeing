*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*---------------------Round 1, 2, and, 3 - Older Cohort data-------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

*---Load data

* Set working directory:
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"
//cd  "C:\Users\User\Desktop\Young Lives"

* Load the older cohort dataset obtained from executing the merging_ do file
do "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\03_Syntax\04_YL_Ethiopia_OC_merging_FINAL.do"

* Drop unnecessary variables
keep ///
/*CONSTRUCTED dataset variables */ ///
/*id variables */ childid* panel* inround* deceased* dint* commid* clustid* careid* ///
/*covariates*/ region* typesite* childloc* chsex* chlang* chethnic* chldrel* agemon* ageyear* bwght* bwdoc* hsleep* hcare* hchore* htask* hwork* hschool* hstudy* hplay* commwork* commsch* agestrtsch* caredu* carehead* careage* caresex* carerel* hhsize* male612* female612* wi_new* hq_new* sv_new* cd_new* ///
/*Education outcomes*/ enrol* preprim* levlread* levlwrit* engrade* entype* hghgrade* timesch* ///
/*Health outcomes*/ bmi* chmightdie* chillness* chinjury* chhprob* chdisability* chdisscale* chhrel* chhealth* cladder* zwfa* zhfa* zbfa* zwfl* underweight* stunting* thinness* chsmoke* chalcohol* ///
/*Sanitation outcomes*/ toiletq* drwaterq* ///
/*ADDED variables*/ ///
/*Accelerators*/ psnp* hex* hexoftr* hexexpr* hextwelve* hexfifteen* hexnineteen* psnpFU* hexp* fampln* edhiv* ///
/*Education outcomes*/ mathscore* langscore* ///
/*Health outcomes*/ chrephealthall* chrephealthbin* chrephealthpreg* chrephealthsti* chrephealthcndm* chrephealthsex* chrephealthserv* chmarr* chpreg* ///
/*Work outcomes*/ hrsdom* hrsdombin* hrsemp* hrsempbin* chjobasp4 ///
/*Covariates*/ wlthindex* shdthbin* shillbin* shfoodbin* shcropbin* shdroughtbin* hcfdis* hcfme* scprmdis* scprmme* scsecdis* scsecme* ///
/*SENSITIVITY variables*/ ///
/*Access to school at round 3*/ enrschr* schminr* trnschr* misschr* gochilr* frcntr* frpstr*

* Order variables
order childid-zwfl4 , alphabetic
order childid clustid* commid* careid* panel* inround* deceased* dint* , first

foreach i of num 1/4{
rename male612`i' malechld`i'
rename female612`i' femalechld`i'
}

* First generate indicator of round
foreach i of num 1/4{
gen round`i' = `i'
}
label define round 1 "1" 2 "2" 3 "3" 4 "4"
label values round* round

* Restrict to participants living outside of Addis Ababa as social programs are 
* targeted in these areas
preserve
table1_mc , by( hexfifteen4  ) vars( ///
/* Participant characteristics */ typesite1 cat \ region1 cat ) onecol missing format( %12.2fc ) percformat( %12.2fc ) pdp(6) percsign("") clear
export excel using "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\04_Tables\0.10 Table HEP Regions 20210212.xlsx", replace
restore

drop if region1 == 5 | region1 == 6

* Restrict to participants followed-up until round 4
generate attrtion = . 
replace attrtion = 0 if inround2 == 1 & inround3 == 1 & inround4 == 1 
replace attrtion = 1 if inround2 == 0  // not in round 2
replace attrtion = 1 if inround3 == 0  // not in round 3
replace attrtion = 1 if inround4 == 0  // not in round 4

tab hextwelve4
tab hexfifteen4
tab hexnineteen4

//Descripitive characteristics of participants LTFU

preserve
table1_mc , by( attrtion  ) vars( ///
/* Participant characteristics */ chsex1 cat \ ageyear1 contn \ stunting1 cat \ chhprob1 cat \ chhrel1 cat\ enrolnew1 cat \ typesite1 cat \ region1 cat\ ///
/* Household characteristics */ hhsize1 contn \ wlthindex1 contn \ ///
/* Caregiver characteristics */ careage1 contn \ caredu1 cat ) onecol missing format( %12.2fc ) percformat( %12.0f ) pdp(6) percsign("") clear
export excel using "C:\Users\william.rudgard\OneDrive - Nexus365\Analysis - Young Lives Acc\04_Tables\0.11 Table LTFU 20210212.xlsx", replace
restore

drop if attrtion == 1

*---Check missing patterns

mdesc ///
/* Baseline covariates */ ///
/* Participant characteristics */ chsex1 ageyear1 stunting1 chhprob1 chhrel1 enrolnew1 typesite1 region1 ///
/* Household characteristics */ hhsize1 wlthindex1 ///
/* Caregiver characteristics */ careage1 caredu1 ///
/* Time-varying covariates */ ///
/* Age started school */ agestrtsch1 ///
/* Household shocks */ shcropbin1 shfoodbinFU4 shdroughtbinFU4 ///
/* Outcome variables */ ///
/* Anthropometric information */ thinness4 ///
/* Child Health */ chhealth4 ///
/* Education */ enrol4 langscore4 mathscore4 /// 
/* Employment */ hrsdombin4 hrsempbin4 ///
/* Gender */ chrephealthpreg4 chrephealthsti4 ///
/* Child marriage */ chmarr4 chpreg4 ///
/* Substance use */ chalcohol4 ///
/* Social protection variables */ ///
/* PSNP */ psnpFU4 ///
/* HEP */ hexfifteen4

egen nmis=rmiss2( ///
/* Baseline covariates */ ///
/* Participant characteristics */ chsex1 ageyear1 stunting1 chhprob1 chhrel1 enrolnew1 typesite1 region1 ///
/* Household characteristics */ hhsize1 wlthindex1 ///
/* Caregiver characteristics */ careage1 caredu1 ///
/* Time-varying covariates */ ///
/* Age started school */ agestrtsch1 ///
/* Household shocks */ shdroughtbinFU4 ///
/* Outcome variables */ ///
/* Anthropometric information */ thinness4 ///
/* Child Health */ chhealth4 ///
/* Education */ enrol4 langscore4 mathscore4 /// 
/* Employment */ hrsdombin4 hrsempbin4 ///
/* Gender */ chrephealthpreg4 chrephealthsti4 ///
/* Child marriage */ chmarr4 chpreg4 ///
/* Substance use */ chalcohol4 ///
/* Social protection variables */ ///
/* PSNP */ psnpFU4 ///
/* HEP */ hexfifteen4 )

tab nmis

mvpatterns ///
/* Baseline covariates */ ///
/* Participant characteristics */ chsex1 ageyear1 stunting1 chhprob1 chhrel1 enrolnew1 typesite1 region1 typesite1 region1 ///
/* Household characteristics */ hhsize1 wlthindex1 ///
/* Caregiver characteristics */ careage1 carehead1 ///
/* Time-varying covariates */ ///
/* Age started school */ agestrtsch1 ///
/* Household shocks */ shcropbin1 shfoodbinFU4 shdroughtbinFU4 ///
/* Outcome variables */ ///
/* Anthropometric information */ thinness4 ///
/* Child Health */ chhealth4 ///
/* Education */ enrol4 langscore4 mathscore4 /// 
/* Employment */ hrsdombin4 hrsempbin4 ///
/* Gender */ chrephealthpreg4 chrephealthsti4 ///
/* Child marriage */ chmarr4 chpreg4 ///
/* Substance use */ chalcohol4 ///
/* Social protection variables */ ///
/* PSNP */ psnpFU4 ///
/* HEP */ hexfifteen4 

* Save wide data
save "Subset data\ethiopia_oc_r1234_wide.dta" , replace

* Reshape data
reshape long  ///
/*CONSTRUCTED dataset variables */ ///
/*id variables */ panel inround deceased dint commid clustid  ///
/*covariates*/ region typesite childloc chsex agemon ageyear caredu careage caresex hhsize malechld femalechld agestrtsch ///
/*Education outcomes*/ enrolnew enrol hghgrade lvlread lvlwrit ///
/*Health outcomes*/ bmi chmightdie chillness chinjury chhprob chdisability chdisscale chhrel chhealth chhealthbin cladder zwfa zhfa zbfa zwfl underweight stunting thinness chsmoke chalcohol ///
/*ADDED variables */ ///
/*Accelerators*/ psnp hex hexoftr hexexpr hextwelve hexfifteen hexnineteen psnpFU ///
/*Education outcomes*/ mathscore langscore ///
/*Health outcomes*/ chrephealthall chrephealthbin chrephealthpreg chrephealthsti chrephealthcndm chrephealthsex chrephealthserv chmarr chpreg ///
/*Work outcomes*/ hrsdom hrsdombin hrsemp hrsempbin chjobasp ///
/*Covariates*/ wlthindex shcropbin shcropbinFU shdroughtbin shdroughtbinFU shdthbin shfoodbin shfoodbinFU shillbin shillbinFU hcfdis hcfme scprmdis scprmme scsecdis scsecme , i( childid) j( round )

* Label additional outcome variables
label var langscore "Literacy"
label var mathscore "Numeracy"
label var chrephealthpreg "Fertility knowledge"
label values chrephealthpreg noyes
label var chrephealthsti "STI knowledge"
label values chrephealthsti noyes
label var chmarr "Child marriage"
label var chpreg "Early pregnancy"
label var hrsdombin "<3 Hrs/day on chores & caring"
label values hrsdombin noyes
label var hrsempbin ">4 Hrs/day on family business & paid work"
label values hrsempbin noyes
label values chalcohol noyes
label values chhealthbin noyes

label define sex 1 "Male" 2 "Female"
label values chsex sex

* Clean up
label values round round

* Save long data
save "Subset data\ethiopia_oc_r1234_long.dta" , replace

*--------------------------------------End-------------------------------------*
