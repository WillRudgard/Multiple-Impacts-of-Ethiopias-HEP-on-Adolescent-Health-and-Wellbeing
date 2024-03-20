*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**
*---------------------------------Accelerators---------------------------------*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**

/* 
Here we extract accelerators to be added to the constructed data. The 
constructed dataset is in LONG format. Subsetted data were kept in wide 
format and merged into reshaped constructed data in seperate merging .do file.
*/

*------------------------------------------------------------------------------*

* Set working directory:
cd "C:\Users\william.rudgard\OneDrive - Nexus365\Data - Young Lives"
//cd  "C:\Users\User\Desktop\Young Lives"

* Check dates of each round
* Round 1
use "UKDA-5307-stata\stata\stata11\r1_oc\ethiopia\etchildlevel8yrold.dta" , replace
sort dint
list dint in 1
* Gregorian: 11 Oct 2002
* Julian: 1 Maskaram 1995

* Round 2
use "UKDA-6852-stata\stata\stata11_se\r2_oc\ethiopia\etchildquest12yrold.dta" , replace
sort CDINT 
list CDINT in 1
* Gregorian: 11 Nov 2006
* Julian: 2 Hedar 1999 

* Round 3
use "UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_childlevel.dta" , replace
sort CDINT 
list CDINT in 1
* Gregorian: 12 Oct 2009
* Julian: 2 Tikimit 2002

* Round 4
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_hh\et_r4_ochh_olderhousehold.dta" , replace
replace DINT = trim(itrim(DINT))
split DINT , gen(CDINT)
generate CDINT11 = date(CDINT1, "DMY")
format CDINT11 %tdD_m_Y
sort CDINT11
list CDINT11 in 1
* Gregorian: 03 Mar 2013
* Julian: 24 Yekatit 2005

*------------------------------------------------------------------------------*
//Step 1: EXTRACT INDICATOR OF HOUSEHOLD RECEIPT OF NGO or GO PROGRAMS @ ROUND 1-4
*------------------------------------------------------------------------------*
 
* Support or assistance through programmes provided by NGOs or GOs at round 2
use "UKDA-6852-stata\stata\stata11_se\r2_oc\ethiopia\etchildlevel12yrold.dta" , replace
rename CHILDID childid
rename ETSUPPRT etsuppt2
rename ACT06 act06
keep childid etsuppt2 act06 
save "Subset data\ethiopia_oc_eversupportprogr2.dta", replace
* Data collection for round 2 was conducted between Nov. 2006 and Jan. 2007

* Support or assistance through programmes provided by NGOs or GOs at round 3
use "UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_householdlevel.dta" , replace
rename etsuppr3 etsuppt3
rename psnprgr3 psnprg3
rename drsprgr3 drsprg3
// Recode participants that have graduated from PSNP as non-benficiaries
replace psnprg3 = 0 if grpsnpr3 == 1 
replace drsprg3 = 0 if grpsnpr3 == 1 
keep childid etsuppt3 psnprg3 drsprg3 actr306
save "Subset data\ethiopia_oc_eversupportprogr3.dta", replace

* Support or assistance through programmes provided by NGOs or GOs at round 4
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_hh\et_r4_ochh_olderhousehold.dta" , replace
rename CHILDCODE childid
rename ETSUPPR4 etsuppt4
rename PSNPRGR4 psnprg4
rename DRSPRGR4 drsprg4
rename HEXOFTR4 hexoftr4
rename HEXEXPR4 hexexpr4
// Look at initial receipt of HEP
recode HEXSTRR4 (20001=2001) (20006=2006) (199=1990) (-77=99) (-9999=99)
replace HEXSTRR4 = HEXSTRR4 + 7 if HEXSTRR4 != 99
rename HEXSTRR4 hexstr4
rename HEXBENR4 hexben4 
// Generate indicator of HEP based on recall at round 4
generate hex1 = 0
generate hex2 = 0 if hexben4 == 0
replace hex2 = 1 if hexstr4 < 2007 & hexstr4 > 99 & hexstr4 != .
replace hex2 = 0 if hexstr4 >= 2007
replace hex2 = . if hexben4 == .
generate hex3 = 0 if hexben4 == 0 
replace hex3 = 1 if hexstr4 < 2010 & hexstr4 > 99 & hexstr4 != .
replace hex3 = 0 if hexstr4 >= 2010
replace hex3 = . if hexben4 == .
generate hex4 = 0 if hexben4 == 0 | hexben4 == 0 
replace hex4 = 1 if hexstr4 < 2014 & hexstr4 > 99 & hexstr4 != .
replace hex4 = . if hexben4 == .
replace hexstr4 = . if hexben4 == 0 | hexstr4 == 99
replace hexstr4 = 2003 if hexstr4 < 2003
// Recode participants that have graduated from PSNP as non-benficiaries
replace psnprg4 = 0 if GRDPRGR4 == 1 
replace drsprg4 = 0 if GRDPRGR4 == 1 
keep childid etsuppt4 hex1 hex2 hex3 hex4 hexben4 hexstr4 hexoftr4 hexexpr4 psnprg4 drsprg4
save "Subset data\ethiopia_oc_eversupportprogr4.dta", replace

*------------------------------------------------------------------------------*
//Step 2: DETAILS OF SUPPORT PROGRAMS: 
*------------------------------------------------------------------------------*

* NOTE: A household will only have records in the support programs data file if 
* etsuppr or etsuppt = 1 at the household level. Both etsuppr and etsuppt 
* were extracted in Step 3 above.

* NOTE: etsuppt is an indicator of a household ever receiving a support program:
* "Has your household ever received support or assistance through programmes
* provided by NGOs or GOs?"
 
* The support program data in Young Lives is arranged in long format, with the 
* length of each participants data based on the number of support programs they
* receive. To merge with the constructed data we must select the programmes
* we are interested in. 

* Major Government programs existing before Young Lives were the Employment
* Generation Scheme (EGS), General Free Food Distribution (GFFD), and 
* Gratuitous relief (GR). These were combined into PSNP described below after 
* severe droughts in 2002/2003 which brought extreme hunger to many.

* Major Government programs implemented over the course of the Young 
* Lives follow-up were the Health Extension Program (HEP), and Productive 
* Safety Net Program (PSNP)

* The PSNP was launched in 2005
* The HEP was launched in 2003

* Hence it is only necessary to consider data from round 2 onwards

*---Details of support programs at round 2
use "UKDA-6852-stata\stata\stata11_se\r2_oc\ethiopia\etsubsupportprograms12.dta" , replace
rename CHILDID childid
rename SUPPRGID supgid
rename SUPKIND supknd
rename SUPWHO supwho
rename SUPSTRT supsrt
rename SUPEND supend
rename SUPFREQ supfrq
rename SUPEXP supexp
keep supknd supwho supsrt supend supfrq supexp childid supgid

* Note: Whilst recorded in the questionnaire there are no responses for 
* educational support at this round of data collection. It would be good to 
* follow-up on this with the YL team.

* Exclude observations that are recorded as only receiving support once a year.
*tab supfrq
*drop if supfrq < 5 | supfrq == 77 

* Exclude observations that are recorded to have stopped receiving support before round 2 (2006).
*tab supend , nolab
* N.B dates are recorded in Julian calendar. To change to Gregorian I add 7 years.
*recode supend (1993=2000) (1994=2001) (1995=2002) (1996=2003) (1997=2004) (1998=2005) (1999=2006)
*drop if supend > 99 /*in other words if the participant has stopped receiving the program */
drop supend

* Exclude observations that are recorded for rare forms of support
* 2 = Child rights protection (N=2)
* 6 = Disability support (N=13)
* 10 = Irrigation development (N=4)
* 13 = Water well development (N=16)
* 15 = Training (N=18)
* 77 = NK (N=1)
drop if supknd == 2
drop if supknd == 6
drop if supknd == 10
drop if supknd == 13
drop if supknd == 15
drop if supknd == 77

* Replace support program ID now that some programs have been dropped
bysort childid : replace supgid = _n

* Check when receipt began
tab supsrt , m  
		
* Summarise receipt of different programs at round 2		
//preserve
//table1_mc , vars(/*Social program*/ supknd cat) onecol missing format(%12.2fc) percformat(%12.0fc) percsign("") clear 
//table1_mc_dta2docx using "Tables\20200408 Social Program R2.docx" , replace
//restore

* Save new social program data at round 2
save "Subset data\ethiopia_oc_supportprogramsr2.dta", replace

*---Details of support programs at round 3
use "UKDA-6853-stata\stata\stata11\r3_oc\ethiopia\et_oc_stblhhsec3supportprogrammes.dta", clear   
rename CHILDID childid
rename SUPPRGID supgid
rename SUPKNDR3 supknd
rename SUPWHOR3 supwho
rename SUPSRTR3 supsrt
rename SUPENDR3 supend
rename SUPFRQR3 supfrq
rename SUPEXPR3 supexp
		
* Drop unecessary variables
drop SUPRIDR3 SUIMR301 SUIMR302

* Exclude observations that are recorded as only receiving support once a year.
*tab supfrq
*tab supfrq, nolab
*drop if supfrq < 5

*Exclude observations that are recorded to have stopped receiving support before round 3 (2009).
*tab supend , nolab                                      
*recode supend (-99=99) (1998=2005) (1999=2006) (2000=2007) (2001=2008) (2002=2009) (2003=2010)
*drop if supend > 99
drop supend

* Exclude observations that are recorded for rare forms of support
* 2 = Child rights protection (N=9)
* 6 = Disability support (N=1)
* 10 = Irrigation development (N=9)
* 13 = Training (N=8)
* 15 = Drinking water provision/development (N=2)
* 17 = Orphan and destitute children support (N=9) 
* 18 = Provision of sanitary facility such as  (N=34)
drop if supknd == 2
drop if supknd == 6
drop if supknd == 10
drop if supknd == 13
drop if supknd == 15
drop if supknd == 17
drop if supknd == 18

* Round 3 includes new information on education support. FYI it possible to back
* date this for when participants began to receive.
* tab supknd supsrt

* Replace support program ID now that some programs have been dropped
bysort childid : replace supgid = _n

* Summarise prevalence of when receipt began
tab supsrt , m /*80% was since 1998; 98% was before 2002*/ 

* Summarise receipt of different programs at round 3		
//preserve
//table1_mc , vars(/*Social program*/ supknd cat) onecol missing format(%12.2fc) percformat(%12.0fc) percsign("") clear 
//table1_mc_dta2docx using "Tables\20200408 Social Program R3.docx" , replace
//restore
	
* Save new social program data at round 3
save "Subset data\ethiopia_oc_supportprogramsr3.dta", replace

*---Details of support programs at round 4
use "UKDA-7931-stata\stata\stata11\r4_oc\ethiopia\oc_hh\et_r4_ochh_support.dta", clear   
rename CHILDCODE childid
rename SPPGIDR4 supgid
rename SUPKNDR4 supknd
rename SUPWHOR4 supwho
rename SUPSRTR4 supsrt
rename SUPENDR4 supend
rename SUPFRQR4 supfrq

* Drop unecessary variables		
drop SUPTARR4

*Exclude observations that are recorded to have stopped receiving support before round 4 (2013).
*tab supend , nolab                                          // 90% of programs continue to be received (-77 is not known)
*recode supend (-9999=99) (9999=99) (999=99) (9969=99) (9966=99) (1992=1999) (1999=2006) (2002=2009) (2003=2010) (2004=2011) (2005=2012) (2006=2013)
*drop if supend > 99 
drop supend

* Exclude observations that are recorded for rare forms of support
* 2 = Child right protection (N=7)
* 6 = Disability support (N=1)
* 10 = Irrigation development (N=12)
* 13 = Training non-agriculture (N=13)
* 15 = Support to plant trees (N=3)
* 17 = Provision of sanitary facility such as  (N=77)
* 18 = Orphan and destitute children support (N=2) 
* 19 = School feeding (N=45)
* 20 = Food aid (not PSNP) (N=5)
* 22 = Other food security program (N=4)
* 23 = Target supplementary feeding program (N=1)
* 24 = Drinking water provision (N=6)
* 25 = Investment in health infrastructure (N=4)
* 29 = Productive assets (N=2)
* 30 = Environmental protection (N=17)
* 31 = Income generation scheme (N=4)
drop if supknd == 2
drop if supknd == 6
drop if supknd == 10
drop if supknd == 15
drop if supknd == 17
drop if supknd == 18
drop if supknd == 19
drop if supknd == 20
drop if supknd == 22
drop if supknd == 23
drop if supknd == 24
drop if supknd == 26
drop if supknd == 27
drop if supknd == 29
drop if supknd == 30
drop if supknd == 31

* Replace support program ID now that some programs have been dropped
bysort childid : replace supgid = _n

* Check when receipt began
tab supsrt , m  

* Summarise receipt of different programs at round 4		
//preserve
//table1_mc , vars(/*Social program*/ supknd cat) onecol missing format(%12.2fc) percformat(%12.0fc) percsign("") clear 
//table1_mc_dta2docx using "Tables\20200408 Social Program R4.docx" , replace
//restore

* It seems that at round 4 there is a much lower participation in the PSNP. 
* Possibly because of graduation?

* Save new social program data at round 4
save "Subset data\ethiopia_oc_supportprogramsr4.dta", replace
		
*---Tidy up receipt of social programs for merging across timepoints		
		
* Unique identifier = combination of childid and support id (supgid)

//Round 2

* Load subsetted data
use "Subset data\ethiopia_oc_supportprogramsr2.dta" , replace
* Reshape data from long to wide
reshape wide supknd supwho supsrt supfrq supexp , i(childid) j(supgid)

* Now that the data has been reshaped it is possible to bring in information
* on whether a participant reported receiving a social program or not.
merge 1:1 childid using "Subset data\ethiopia_oc_eversupportprogr2.dta"
drop _merge

* Generate indicator of PSNP, HEP, family planning, and HIV education
generate psnp2 = 1 if supknd1 == 3 | supknd2 == 3 | supknd3 == 3 | supknd4 == 3 | supknd5 == 3 | /*Conditional transfer/cash for work (CFW)/cash EGS*/ ///
 supknd1 == 4 | supknd2 == 4 | supknd3 == 4 | supknd4 == 4 | supknd5 == 4 | /*Conditional transfer/Food for work (FFW)*/ /// 
 supknd1 == 14 | supknd2 == 14 | supknd3 == 14 | supknd4 == 14 | supknd5 == 14 /*Unconditional transfer/food aid, gratuitous food aid*/
generate fampln2 = 1 if supknd1 == 8 | supknd2 == 8 | supknd3 == 8 | supknd4 == 8 | supknd5 == 8 /*Family planning*/
generate edhiv2 = 1 if supknd1 == 7 | supknd2 == 7 | supknd3 == 7 | supknd4 == 7 | supknd5 == 7 | /*Education about HIV*/ ///
 supknd1 == 11 | supknd2 == 11 | supknd3 == 11 | supknd4 == 11 | supknd5 == 11 /*Mother to child HIV/AIDS*/
generate hexp2 = 1 if supknd1 == 9 | supknd2 == 9 | supknd3 == 9 | supknd4 == 9 | supknd5 == 9 /*Health extension services*/ 

* Replace missing with indicator of no receipt 		 
foreach var of varlist psnp2 fampln2 edhiv2 hexp2 {
replace `var' = 0 if `var' == .
tab `var' , m
}

* Drop variables from reshape
forvalues i = 1/5{
drop supknd`i'
drop supwho`i'
drop supsrt`i'
drop supfrq`i'
drop supexp`i'
}

* Generte additional variables for consistency
generate hexoftr2 = . 
generate hexexpr2 = .

* Save updated social program data at round 2
save "Subset data\ethiopia_oc_supportprogramsr2.dta" , replace

//Round 3

* Load subsetted data
use "Subset data\ethiopia_oc_supportprogramsr3.dta" , replace

* Reshape data from long to wide
reshape wide supknd supwho supsrt supfrq supexp , i(childid) j(supgid)

* In Round 3, additional information on receipt of the PSNP was collected 
* earlier in the questionnaire.
* Now that the data has been reshaped it is possible to bring in information
* on this using a merge.
merge 1:1 childid using "Subset data\ethiopia_oc_eversupportprogr3.dta"
drop _merge

* Generate indicators of PSNP, HEP, family planning, and HIV education
generate psnp3 = 1 if supknd1 == 3 | supknd2 == 3 | supknd3 == 3 | supknd4 == 3 | supknd5 == 3 | /*PSNP (public work program) for Cash*/ ///
 supknd1 == 4 | supknd2 == 4 | supknd3 == 4 | supknd4 == 4 | supknd5 == 4 | /*PSNP (public work program) for food*/ ///
 psnprg3 == 1 | /*Was any member of the household registered as a beneficiary of the PSNP Public works programme in the last 12 months*/ ///
 supknd1 == 14 | supknd2 == 14 | supknd3 == 14 | supknd4 == 14 | supknd5 == 14 | /*PSNP (direct support/ food/ cash aid)*/ ///
 drsprg3 == 1 /* Was any member of the household registered as beneficiary of Direct Support in the last 12 months?*/
generate fampln3 = 1 if supknd1 == 8 | supknd2 == 8 | supknd3 == 8 | supknd4 == 8 | supknd5 == 8 /*Family planning*/
generate edhiv3 = 1 if supknd1 == 7 | supknd2 == 7 | supknd3 == 7 | supknd4 == 7 | supknd5 == 7 | /*Education about HIV*/ ///
		  supknd1 == 11 | supknd2 == 11 | supknd3 == 11 | supknd4 == 11 | supknd5 == 11 /*Mother to child HIV/AIDS*/
generate hexp3 = 1 if supknd1 == 9 | supknd2 == 9 | supknd3 == 9 | supknd4 == 9 | supknd5 == 9 /*Health extension services*/ 

* Replace missing with indicator of no receipt 		 
foreach var of varlist psnp3 fampln3 edhiv3 hexp3 {
replace `var' = 0 if `var' == .
tab `var' , m
} 

* Drop variables from reshape
forvalues i = 1/5{
drop supknd`i'
drop supwho`i'
drop supsrt`i'
drop supfrq`i'
drop supexp`i'
}

* Drop additional unecessary variables
drop psnprg3 drsprg3

* Generte additional variables for consistency
generate hexoftr3 = .
generate hexexpr3 = .

* Save updated social program data at round 3
save "Subset data\ethiopia_oc_supportprogramsr3.dta", replace

//Round 4 

* Load subsetted data
use "Subset data\ethiopia_oc_supportprogramsr4.dta" , replace
* Reshape data from long to wide
reshape wide supknd supwho supsrt supfrq , i(childid) j(supgid)

* In Round 4, additional information on receipt of the Health Extension Program 
* and PSNP was collected earlier in the questionnaire.
* Now that the data has been reshaped it is possible to bring in information
* on this program using a merge.
merge 1:1 childid using "Subset data\ethiopia_oc_eversupportprogr4.dta"
drop _merge

* Generate indicators of PSNP, HEP, family planning, and HIV education
generate psnp4 = 1 if supknd1 == 3 | supknd2 == 3 | supknd3 == 3 | supknd4 == 3 | supknd5 == 3 | supknd6 == 3 | supknd7 == 3 | /*Public work program for cash*/ ///
 supknd1 == 4 | supknd2 == 4 | supknd3 == 4 | supknd4 == 4 | supknd5 == 4 | supknd6 == 4 | supknd7 == 4 | /*Public work program for food*/ ///
 psnprg4 == 1 | /*Were you or any member of this household registered as a beneficiary of the PSNP – Public Works program in the past 12*/ ///
 supknd1 == 25 | supknd2 == 25 | supknd3 == 25 | supknd4 == 25 | supknd5 == 25 | supknd6 == 25 | supknd7 == 25 | /*PSNP (direct support/food/cash aid)*/ ///
 drsprg4 == 1 /*Were you or any member of this household registered as beneficiary of Direct Support (transfers of cash, food or other goods without requiring individuals to work) in the past 12 months*/
generate fampln4 = 1 if supknd1 == 8 | supknd2 == 8 | supknd3 == 8 | supknd4 == 8 | supknd5 == 8 | supknd6 == 8 | supknd7 == 8 /*Family Planning*/ 
generate edhiv4 = 1 if supknd1 == 7 | supknd2 == 7 | supknd3 == 7 | supknd4 == 7 | supknd5 == 7 | supknd6 == 7 | supknd7 == 7 | /*Education about HIV*/ ///
 supknd1 == 11 | supknd2 == 11 | supknd3 == 11 | supknd4 == 11 | supknd5 == 11 | supknd6 == 11 | supknd7 == 11 /*Prevention of Mother to child HIV/Aids transmission*/
generate hexp4 = 1 if hexben4 == 1 /*Is any HHM a beneficiary/member of the Health extension program (HEP)?*/
 
* Replace missing with indicator of no receipt 		 
foreach var of varlist psnp4 fampln4 edhiv4 hexp4 {
replace `var' = 0 if `var' == .
replace `var' = . if etsuppt4 == 77
tab `var' , m
}
 
* Drop variables from reshape
forvalues i = 1/7{
drop supknd`i'
drop supwho`i'
drop supsrt`i'
drop supfrq`i'
} 		

* Drop additional unecessary variables
drop psnprg4 drsprg4 

* Participants unique ID in round 4 is different to preceeding rounds. To merge 
* it with other rounds it is necessary to adapt slighty:
generate childid2 = "ET" + string(childid , "%06.0f") 
drop childid
rename childid2 childid

* Save updated social program data at round 4
save "Subset data\ethiopia_oc_supportprogramsr4.dta", replace

*---Merge details of support programs between rounds

* Load round 2 social program data
use "Subset data\ethiopia_oc_supportprogramsr2.dta" , replace

*---Merge details of support programs at round 2 and 3

* Merge to round 3 data
merge 1:1 childid using "Subset data\ethiopia_oc_supportprogramsr3.dta"
drop _merge

*---Merge details of support programs at round 2, 3 and 4
merge 1:1 childid using "Subset data\ethiopia_oc_supportprogramsr4.dta"
drop _merge 

* Add round 1 variables
generate psnp1 = .
generate fampln1 = .
generate edhiv1 = .
generate hexp1 = .

* Tidy up labelling
forvalues i = 1/4{
label var psnp`i' "PSNP cash/food & direct support"
label var fampln`i' "Family planning services"
label var edhiv`i' "HIV education services" 
label var hexp`i' "HEP, reported at EACH Round"
label var hex`i' "HEP, recalled at ONLY Round 4"
}

label define yesno 0 "No" 1 "Yes"

foreach var in psnp fampln edhiv hexp hex {
forvalues i = 1/4{
label values `var'`i' yesno
}
}

*-----Final support programs data
save "Subset data\ethiopia_oc_supportprograms.dta", replace

*-------------------------------------End--------------------------------------*
