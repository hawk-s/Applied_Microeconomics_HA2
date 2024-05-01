// Clear memory and any existing datasets
clear all

// Set the directory where your data is located
cd "C:\Users\janhr\Downloads\data"

use new_births_data.dta


// Display duplicates in the births dataset based on specified variables
duplicates report country year subnational cluster hhno linewm imicspsu imicscluster




// reshape wide country year subnational cluster hhno linewm imicspsu imicscluster

// Sort the dataset by the specified variables
sort country year subnational cluster hhno linewm imicspsu imicscluster -agebh bhorder_grp //reverse the sort order based on age

// Generate a variable to indicate the birth order for each woman
by country year subnational cluster hhno linewm imicspsu imicscluster: gen birthorder = _n

tabulate birthorder

// Display duplicates in the births dataset based on specified variables
duplicates report country year subnational cluster hhno linewm linenobh imicspsu

// Drop duplicates based on certain variables
duplicates drop country year subnational cluster hhno linewm linenobh imicspsu, force


// Save the births dataset with the birth order variable as a new file
save new_births_data_wo_duplicates.dta, replace

use new_births_data_wo_duplicates.dta

// List all variables in the dataset 
ds

// Define the variables to include
// local include_vars "linenobh agebh bhtwin bhsex bhalive bhbetweencheck bhdobflag bhorder_grp bhmomage_grp doi dobbh birthorder"


// Reshape the dataset wide
reshape wide serial linenobh agebh bhtwin bhsex bhalive bhbetweencheck bhdobflag bhorder_grp bhmomage_grp doi dobbh, i(country year subnational cluster hhno linewm imicspsu imicscluster) j(birthorder)

// Display duplicates in the births dataset based on specified variables
duplicates report country year subnational cluster hhno linewm imicspsu imicscluster 

// Save the births dataset with the birth order variable as a new file
save final_births_data_reshaped.dta, replace

// Load the women dataset
use new_women_data.dta

// Perform the one-to-one merge based on the new variable
merge 1:1 country year subnational cluster hhno linewm imicspsu imicscluster using final_births_data_reshaped.dta

// Display duplicates in the births dataset based on specified variables
duplicates report country year subnational cluster hhno linewm imicspsu imicscluster 

// Delete non-matched - non-matched are usually single mothers for some reason... 
keep if _merge == 3


//assert !missing(agebh2)
* Create an assertion to test if all values in agebh2 are lower than in agebh1
//assert agebh2 < agebh1

* uncomment the following to see the reason why the agebh1 !> agebh2
// list if !(agebh2 < agebh1) 

// list if (!(agebh2 < agebh1) & !missing(agebh2)) 


* -> its because of missing or NIU values in the ageb2, i.e. if the 2nd child was not born or died

tabulate agebh1, missing
tabulate agebh2, missing


// Save the merged dataset
save new_merged_data.dta, replace

* how does he account for dead children?? that might have a huge effect on happiness!...





/////////////////////////////////////////////////////////////////////////////////////////

 //////   //////   //////    //   //   // 
 //  //   //  //   //       ///   //  //  
 //  //   //  //   //      // //  // //    
 ////     ////     ////    ////   ////       
//  //   //  //   //     //   //  //  //    
//  //  //   //  //     //    //  //   //   
/////  //    // ////// //     //  //    //   

////////////////////////////////////////////////////////////////////////////////////////




// Core sample data processing follows:

use new_merged_data.dta


drop if missing(agebh1) // actually it is births dataset so its no surprise no observation was deleted, there is for each woman at least one birth..

drop if missing(agebh2) // (65,526 observations deleted)

drop if !missing(agebh4) // (137,457 observations deleted)


tabulate agebh4, missing


* for the core sample we keep only the women with 2 or more alive children...completely ommiting the death possibility (i.e. we do not care if any child later than 2nd died (we delete those as well), and we delete the woman if one of her first two children died...):

tabulate agebh1, missing

tabulate agebh2, missing

tabulate agebh3, missing

drop if agebh1 == 99 // 99 = NIU, not in universe

drop if agebh2 == 99

drop if agebh3 == 99

tabulate agebh1, missing

tabulate agebh2, missing

tabulate agebh3, missing

drop if agebh1 == 98 // 98 = Missing / unknown
drop if agebh2 == 98

drop if agebh3 == 98

tabulate agebh1, missing

tabulate agebh2, missing

tabulate agebh3, missing

//assert agebh2 <= agebh1
list if !(agebh2 <= agebh1) // MISTAKE IN THE DATASET - most likely the order of children is wrong... so we drop it:

drop if !(agebh2 <= agebh1)


tabulate agebh3

* the following calculates the number of missing observations for agebh3 - when no third children there is:
//generate result = 187069 - 82672, replace force
//display result


* and it corresponds to the following number of false cases (thus its fine):
//assert agebh3 <= agebh1

//list if !(agebh3 <= agebh1)



// List observations where lshappy is missing
tabulate lshappy, missing

// List observations where lsladder is missing
tabulate lsladder, missing

// Drop observations with missing values for variable1
drop if missing(lshappy)

// List observations where lshappy is missing
tabulate lshappy, missing

// List observations where lsladder is missing
tabulate lsladder, missing

describe lshappy



// Drop observations where lshappy is not in the range of values
drop if !inrange(lshappy, 1, 5) 

// Drop observations where lshappy is not in the range of values
drop if !inrange(lsladder, 0, 10)



// List observations where lshappy is missing
tabulate lshappy, missing

// List observations where lsladder is missing
tabulate lsladder, missing


// Save the core dataset
save core_data.dta, replace








  //////////////////////
 // ANALYSIS FOLLOWS //
//////////////////////


use core_data.dta

*********
****** THE KEY VARIABLES (GENERATE): ********

// Generate the samesex dummy variable - instrument Z in the paper
generate samesex = (bhsex1 == bhsex2)

// Generate the thirdbirth dummy variable - variable D in the paper - indicates if woman has third child
generate thirdbirth = (agebh3 != .)

// Generate the other instrument Z - 1 if the first two ch. are boys
generate twoboys = ((bhsex1 == 1) & (bhsex2 == 1))

// Generate the other instrument Z - 1 if the first two ch. are girls
generate twogirls = ((bhsex1 == 2) & (bhsex2 == 2))

********



******* COVARIATES: **********

// Generate the age of mother at the first birth
gen agefirstbirth = agewm - agebh1

summarize agefirstbirth

list if (agefirstbirth == 0) // seems like mistake - mom and son are both 24 years old... delete this observation:

drop if (agefirstbirth == 0)

summarize agefirstbirth

list if (agefirstbirth == 4) //not very plausible, although not theoretically impossible, but still delete:

drop if (agefirstbirth == 4)

summarize agefirstbirth


list if (agefirstbirth == 5) //the same - delete:

drop if (agefirstbirth == 5)

summarize agefirstbirth
list if (agefirstbirth == 7) //still outlier:

drop if (agefirstbirth == 7)

summarize agefirstbirth
//list if (agefirstbirth == 8) //5 observations.. keep it from here.


// Transformation to 5 year interval categorical variable
egen age_dummy = cut(agefirstbirth), at(0 15 20 25 30 35 40 111) 
egen age_category = group(age_dummy) 

// (1.) FIRSTBIRTH AGE DUMMIES (based on the categorical var; each age group one dummy):
gen agefirstbirth_15below = (age_category == 1)
gen agefirstbirth_15_19 = (age_category == 2)
gen agefirstbirth_20_24 = (age_category == 3)
gen agefirstbirth_25_29 = (age_category == 4)
gen agefirstbirth_30_34 = (age_category == 5)
gen agefirstbirth_35_39 = (age_category == 6)
gen agefirstbirth_above_39 = (age_category == 7)



// (2.) MOTHERS AGE DUMMIES (for each age one dummy):
summarize agewm

// Set the range 
local min_age = 15
local max_age = 49

// Create FINAL dummy variables for each age
forvalues age = `min_age'/`max_age' {
    gen age_`age' = (agewm == `age')
}
// -> names of those dummies are 'age_15', 'age_16', etc.



// (3.) GENDER OF THE FIRST CHILD (dummy where boy=1, girl=0; the original formating of bhsex1 was Male=1, Female=2):

gen firstgender = (bhsex1 == 1) //boy=1, girl=0


// (4.) URBAN/RURAL
summarize urban, detail
tabulate urban

* rural = 2, urban = 1, what is 3, 4, 5?
list if (urban == 5)  //so there is no 3 or 4, 5 == refugee camp ... -> delete refugee camp??

// yes:
drop if (urban == 5) //(375 observations deleted)

tabulate urban

// FINAL binary dummy - rural/urban only:
gen locationdummy = (urban == 1) // 1 if woman lives in a city, 0 if not


save full_core_data.dta, replace

*************************************************
////////////////////////////////////////////////
//////////// SUMMARY STATS: ///////////////////
//////////////////////////////////////////////
*********************************************


* Compute the mean of the variables for each condition
collapse (mean) agewm agefirstbirth marrcurr locationdummy mobilewm lshappy lsladder, by(samesex thirdbirth)

* Label the samesex and thirdbirth variables
label define samesex_labels 0 "No" 1 "Yes"
label define thirdbirth_labels 0 "No" 1 "Yes"
label values samesex samesex_labels
label values thirdbirth thirdbirth_labels

* Display the mean values
list


// Key summary stats (Table 1 paper):
*same_sex // given: yes - samesex=1, no - samesex=0  (Z)
*third_birth // given yes - thirdbirth=1, no - thirdbirth=0 (D)
*always_taker // for samesex=0 and thirdbirth=1 (at the same time)
*complier_1   // for samesex=0 and thirdbirth=0 (at the same time)
*complier_2   // for samesex=1 and thirdbirth=1 (at the same time)
*never_taker  // samesex=1 and thirdbirth=0
// d - third child, z - same sex of the 1st two

//we have just always takers etc..

clear

***************************************
***************************************
****************MODELS*****************
***************************************
***************************************

use full_core_data.dta

* OLS of lshappy on thirdbirth
regress lshappy thirdbirth

regress lsladder thirdbirth



* OLS !! With Country and Year Fixed Effects !!:

// xtreg lsladder thirdbirth, fe 

tabulate year
tabulate country

* Year fe:
gen year17_fe = (year == 2017)
gen year18_fe = (year == 2018)
gen year19_fe = (year == 2019)
gen year20_fe = (year == 2020)
gen year21_fe = (year == 2021)

//summarize country
//describe country
tabulate country

* Country fe:
gen country1fe = (country == 12) //algeria
gen country2fe = (country == 50) //bangldesh
gen country3fe = (country == 140) //Central Africa Republic
gen country4fe = (country == 148) //Chad
gen country5fe = (country == 180) //Congo, Democratic Republic of the
gen country6fe = (country == 242) //fiji
gen country7fe = (country == 270) //Gambia
gen country8fe = (country == 275) //State of Palestine
gen country9fe = (country == 288) //Ghana
gen country10fe = (country == 296) //Kiribati
gen country11fe = (country == 368 ) //Iraq
gen country12fe = (country == 426) //Lesotho
gen country13fe = (country == 454) //Malawi
gen country14fe = (country == 496) //Mongolia
gen country15fe = (country == 524) //Nepal
gen country16fe = (country == 566) //Nigeria
gen country17fe = (country == 586) //Pakistan
gen country18fe = (country == 624) //Guinea-Bissau
gen country19fe = (country == 678) //Sao Tome and Principe
gen country20fe = (country == 694) //Sierra Leone
gen country21fe = (country == 704) //Viet Nam
gen country22fe = (country == 716) //Zimbabwe
gen country23fe = (country == 740) //Suriname
gen country24fe = (country == 768) //Togo
gen country25fe = (country == 776) //Tonga
gen country26fe = (country == 798) //Tuvalu
gen country27fe = (country == 807) //Macedonia, The Former Yugoslav Republic
gen country28fe = (country == 882) //Samoa

// xtreg lsladder thirdbirth i.year i.country



// with fe:

* List all variables in the dataset
ds

* Filter the results to include only variables with names starting with 'country' and ending with 'fe'
local country_fe_vars
foreach var of varlist _all {
    if regexm("`var'", "^country[0-9]+fe$") {
        local country_fe_vars `country_fe_vars' `var'
    }
}

* Display the list of variables with names in the format 'country1fe', 'country2fe', etc.
di "`country_fe_vars'"


// OLS with country and year fixed effects:
regress lsladder thirdbirth year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe


/// -> with the country and year fixed effects we are approaching R2 of 0.1, i.e. 10%




* List all variables in the dataset
ds

* Filter the results to include only variables with names starting with 'age_'
local age_vars
foreach var of varlist _all {
    if strpos("`var'", "age_") == 1 {
        local age_vars `age_vars' `var'
    }
}

* Display the list of variables with names in the format 'age_15', 'age_16', etc.
di "`age_vars'"


* with Covariates (agefirstbirth_above_39 and age_49 not included in the regression to prevent dummy variable trap):
regress lsladder thirdbirth firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 


******* IV (without covariates): *******

* 1st stage regression (OLS)
regress thirdbirth samesex

* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_hat, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_hat





* Conduct IV estimation using samesex as the instrument for thirdbirth
ivregress 2sls lsladder (thirdbirth = samesex)


* Perform J-test (overidentification test)
// estat overid


// With fixed effects:
*1st stage
regress thirdbirth samesex year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe

* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_fe_hat, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_fe_hat



************OLS with COVARIATES and Country and Year FIXED EFFECTS:
regress lsladder thirdbirth firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe










****** IV (with covariates): *******

* 1st stage regression (OLS)
regress thirdbirth samesex firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 


* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_cov_hat, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_cov_hat


* Conduct IV estimation using samesex as the instrument for thirdbirth
ivregress 2sls lsladder (thirdbirth = samesex firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48)


* Perform J-test (overidentification test)
estat overid //quite bad, the p-values are both 0...




*******************************************************
****** IV (with covariates and FIXED EFFECTS): *******
******************************************************

* 1st stage regression (OLS)
regress thirdbirth samesex firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe


* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_fe_cov_hat, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_fe_cov_hat


* Conduct IV estimation using samesex as the instrument for thirdbirth (the same as above)
ivregress 2sls lsladder (thirdbirth = samesex firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe)


* Perform J-test (overidentification test)
estat overid //quite bad, the p-values are both 0...


////////////////////////////////////////////////////////////
///////// Now using twoboys and twogirls: //////////////////
////////////////////////////////////////////////////////////
*just simply with all fixed effects:

******* IV (without covariates): *******

* 1st stage regression (OLS)
regress thirdbirth twoboys year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe

* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_est, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_est


// twoboys seems not to be valid instrument...


//however, with covariates it seems to be ok:

* 1st stage regression (OLS)
regress thirdbirth twoboys firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe


* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_hat, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_hat



* Conduct IV estimation using twoboys as the instrument for thirdbirth
ivregress 2sls lsladder (thirdbirth = twoboys firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48)







****NOW 2 GIRLS*****

******* IV (without covariates): *******

* 1st stage regression (OLS)
regress thirdbirth twogirls year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe

* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_est2, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_est2


// twogirls seems to be valid instrument...


//with covariates:

* 1st stage regression (OLS)
regress thirdbirth twogirls firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48 year17_fe year18_fe year19_fe year20_fe country1fe country2fe country3fe country4fe country5fe country6fe country7fe country8fe country9fe country10fe country11fe country12fe country13fe country14fe country15fe country16fe country17fe country18fe country19fe country20fe country21fe country22fe country23fe country24fe country25fe country26fe country27fe


* Obtain predicted values of thirdbirth from the first stage regression
predict thirdbirth_hat2, xb

* 2nd stage regression (OLS)
regress lsladder thirdbirth_hat2



* Conduct IV estimation using twogirls as the instrument for thirdbirth
ivregress 2sls lsladder (thirdbirth = twogirls firstgender locationdummy agefirstbirth_15below agefirstbirth_15_19 agefirstbirth_20_24 agefirstbirth_25_29 agefirstbirth_30_34 agefirstbirth_35_39 age_15 age_16 age_17 age_18 age_19 age_20 age_21 age_22 age_23 age_24 age_25 age_26 age_27 age_28 age_29 age_30 age_31 age_32 age_33 age_34 age_35 age_36 age_37 age_38 age_39 age_40 age_41 age_42 age_43 age_44 age_45 age_46 age_47 age_48)




// the time and country fixed effects seem to increase the r2, but not change the coefficients or standard errors significantly...
