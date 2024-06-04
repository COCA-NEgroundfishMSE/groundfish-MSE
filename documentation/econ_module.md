

# Economic module documentation
### Min-Yang Lee; Anna Birkenbach (Min-Yang.Lee@noaa.gov; abirken@udel.edu)

<br> Describes the code that implements the "Economic Simulation Module" in the management strategy evaluation.  


## Overview
The code adds an  econonomic component to the MSE model.   When mproc.csv contains a row with ``ImplementationClass=="Economic"``, the economic model will run. The ``runSim.R`` file has been modified to allow for an economic model of harvesting to substitute for a standardFisheries model of implementation error.  This is done with the following if() statement 
```
        if(mproc$ImplementationClass[m]=="Economic"){}
```
The economic module can be viewed as an alternative to the ``get_implementationF()`` function in a the standard fisheries model.  It takes inputs from the stock dynamics models and outputs an F_full.  It also constructs some economic metrics, but I haven't coded where to save them yet.


## The Economic model of Targeting
The population of vessels in the statistical model is: "Vessels that landed groundfish in the 2004-2015 time period, primarily used gillnet or trawl to catch groundfish, elected to fish in the sector program in 2010-2015, and were not falsifying their catch or sales records."  *i* indexes individuals, *n* indexes target, and *t* indexes time (days).

The statistical economic module has two stages. In the first stage, we estimate this equation to model expected harvests.   

```math
H_{nit}=h(q_{ni},E_{nit},{X_{it})
```
This is estimated equation-by-equation with ordinary least squares, using a log-log functional form.


```math
log H_{nit}= log q + b logE + clog X + e
```
although there are more than just these 3 explanatory variables.

Catchability *q* varies by vessel-target.  The results are used to predict expected harvest of target $n$. These are then adjusted to account for the jointness in catching fish. For example, a trip that is targeting GB cod and that lands 1000 lbs of GB cod is also likely to land 500 lb of GB haddock, 200 lb of pollock, and 80 lb of skates.  We track all these individually and multiply by expected prices to construct expected revenue for vessel *i*'s trip that targets GB cod on day *t*. We repeat for all *i*,*n*, *t* to construct expected revenue for all feasible choices.  Some of these things also have quota costs -- we subtract quota costs from the expected revenue.

In the second stage, we estimate the probability that a vessel will target "thing" t: 
```math
P[Target_{nit}] =P(Revenues_{nit}, Costs_{nit}, Z_{nit})
```
We observe whether the vessel actually targeted a thing or did not. These statistical models are referred to as discrete-, binary-, or multinomial- choice models.  The theoretical model underneath this is a Random Utility Model.  Currently, we're using an Alternative-specific Conditional Logit, but we're exploring other options, including nested and mixed logits. Estimation of the asc logit is by maximum likelihood (or quasi-ML, can't remember).

We can simulate either the production or targeting equations at any values of the explanatory variables: for example changes in the trawl survey (used as a biomass proxy) can affect changes in harvest, which feeds into expected revenue and eventually the target equation.  Changes in costs or weather would directly affect the targeting equation.   The biomass proxy that goes into the harvest equation is the log of the trawl survey weights (in kg), the average of the spring and fall surveys is used.  The MSE model keeps track of weight-at-age (mt), numbers-at-age (individuals), and total biomass (N*waa). All I need to do is multiplyby 1000 and take the natural log.

We can also simulate what happens when a fishery (GOM Cod, Pollock, Skates) are closed -- how does fishing effort redistribute to other targets?

McFadden,  D.  L.  1974.  Conditional  logit  analysis  of  qualitative  choice  behavior.  In Frontiers  in  Econometrics,  ed.P.  Zarembka,  105–142.  New  York:  Academic  Press

For both the production and targeting models, the unit of observation is a hullnum-day.

The statistical estimation of the model takes place externally to the MSE model -- there isn't a need to have this occur simultaneously (yet).

The econometric model of targeting uses Real (1st quarter of 2016) US dollars, deflated using WPU0223 - the PPI for Unprocessed and Prepared Seafood.

The production regressions use ``log_trawl_survey_weight`` as a right hand side variable. We update this inside the model from the ``obs_sumEconIW`` and ``sumEconIW`` terms.

## Quota Price submodel

### In Brief

The quota price model uses the econometric results of Lee and Demarest (In Review).  Lee and Demarest estimate two step model to understand the determinants of quota prices in groundfish from 2010-2019.  In the first step, a hedonic price function is estimated on transactions-level data to recover the per-pound price of quota for each stock. In the second step, a reduced form model is estimated to explain the variation in quota prices using output prices, quota remaining, observer coverage rates, and other explanatory variables.  "Corner solutions," characterized by excess supply of quota (low quota utilization rates) and a zero price are prevalent; therefore a hurdle model with an exponential functional form for the outcome equation was used.  The preferred specification in Lee and Demarest (2019) includes a Spatial Lag X term; this term is difficult to simulate and excluded.

The quota price model was estimated in Real (1st quarter of 2010) US dollars, using the GDP Implicit Price Deflator (GDPDEF). Therefore, the quota price submodel first predicts quota prices in Real 2010 US dollars, then converts them to 2016Q1 dollars to match the units of the targeting model. 

### Technical Details

Quota price coefficients are stored in ``quotaprice_coefs_exponential.Rds`` and read into memory by ``setupEconType.R`` 

The ``fishery_holder`` data.table holds the catch limit (sectorACL) and cumulative catch (cumul_cat), by stock (spstock2). These are determined inside the coupled model and computed daily, although the quota prices are only updated quarterly.

The ``quarterly_prices`` data.table holds live prices (2010Q1 GDP), a conversion factor to get to 2016Q1 SFD dollars, and the proportion_obsered. 

## Feedbacks between the biological and Economic model components

There are a few feedback loops between the biological, management, and economic models.  The management model contains a control rule for the Fishing Mortality Rate (F).  The control rule is combined with the estimated biomass and the overfished status to determine the ACL (mt). The biological model also simulates a trawl survey.

1.  A portion of the ACL is immediately deducted because it is caught by recreational vessels, non-groundfish vessels, vessels in state-waters, or simply groundfish vessels that opted out of the catch share fleet and are not part of the modeled fleet.  We set these deductions at either the historical averages or their actual allocations.  When the catch-share fleet's catch of a stock reaches the ACL, fishing for that stock, and other stocks caught with it, is closed.
2.  The ACL affects quota prices through the "quota remaining" term.  When there is abundant quota remaining, the price of quota is likely to be zero. As the aggregate supply of quota decreases, the quota prices increases.
3.  The production regressions use the the (natural) "log of trawl survey biomass (kg)" as an explanatory variable where possible.  Increases in trawl survey generally increase the amount of a stock that is caught on a trip. For the stocks with full biological models, we are able to allow catch on a trip (and therefore revenue)  to be a function of environmental conditions.  


## Shortcomings

As with all models, there are some shortcomings:

1. Output prices are exogenous to the economic model.  Daily prices are fixed, which is unrealistic. 
2. "Only" five stock models.  While it would be best to get "all" of the stock models, this is pretty good. There's a GOM stock (Cod), 3 GB stocks (Yellowtail, Cod, and Haddock), and unit stock (pollock).
3. Year dummy variables -- The "other" target in the expected harvest equation contains a set of dummies for the fishing year. 

## The Main Simulation code

### Options
We can set some options using the mproc.csv file. Notably:

* **EconType :** Multi or Single.  Multi is more realistic.
   Multi --> a closure in a stockarea closes everything in that stockarea (no landings of GB Cod if GB haddock is closed)
   Single --> a closure in a stockarea does not close everything in that stockarea ( landings of GB Cod allowed if GB haddock is closed)
   
* **CatchZero :** Governs catch when a stock is closed.
  TRUE --> no catch of GB Cod if GB cod is closed.
  FALSE --> catch of GB Cod happens even if GB cod is closed (but all catch would be discarded).
* **EconName :** A short name for the scenario. "pre" or "post" in the naming conventions refers to the coefficients used ie (coefs1, coefs2, coefsnc1 and coefsnc2)
* **EconData :** stub for which dataset to use (see data processing steps). 
* **MultiplierFile :** Multiplier file to use.Currently unused.  
* **OutputPriceFile :** Output prices to use. Currently unused.
* **InputPriceFile :** Input prices to use, including quota prices. Currently unused.
* **ProdEqn :** suffix for the production equation (see set_om_parameters_global.R for some examples).  Currently, the choices are just pre and post.
* **ChoiceEqn :** suffix for the choice equation (see set_om_parameters_global.R for some examples). Currently, the choices are just pre and post.  But options for noconstant or something else could be set up.

This is also in the mproc documentation.


There's a pile of code.

* **runEcon_module.R :**  is a *working* economic module.

* **setupYearIndexing.R:** sets up a small data.table that keeps track of year indices. 

* **withinYearAdmin.R:** Operates on that datatable every year.

* **loadsetRNG.R :**  code to load/reset the RNG state based on a list.

* **speedups_econ_module2.R :**  code for benchmarking the economic model.
 
There are  "processes" files that run one time per simulation run: 
* **genBaselineACLs.R:** This is used to construct "baseline" ACLs for the non-modeled stocks. That includes Groundfish *and* non-groundfish stocks like lobster or skate that either caught with groundfish or altenatives to taking a groundfish trip.

* **genEcon_Containers.R:** Gets called in the runSetup.R file. It sets up a few placeholders for Fleet level economic outputs.

* **loadEcon2.R:** Gets called in the runSim.R file.  Loads in a single large data.table that remains in memory for one simulated year.  These files are too big to load and hold in memory for the entire simulation.  Also loads in input prices, output prices, multipliers, and quota prices.

* **setupEconType.R:** Parses the mproc file and loads in data for economic model runs (multipliers, output prices, input prices, production equation, choice equation, quota price coefficients and indep vars).

Functions - these run many times per simulation:

* **get_bio_for_econ:** passes *things* from the biological model (in stock[[i]]) to the economic model.

* **get_fishery_next_period:** adds up catch from individual vessels to the daily level and then aggregates with prior catch.  Checks if the sector sub-ACL is reached and closes the fishery if so.
* **get_fishery_next_period_areaclose:** adds up catch from individual vessels to the daily level and then aggregates with prior catch.  Checks if the sector sub-ACL is reached and closes the fishery if so.  For the allocated multispecies stocks, this creates and extracts column that indicates if that stockarea is closed.

* **get_joint_production:** Replaces the catch multiplier, landings multiplier, quota prices, lag prices, and prices with catch (lbs), landings(lbs), quota prices, lag prices, and prices.  This accounts for the jointness in production. These variables are now a little misleading in names.  However, I chose to replace instead of create new columns to save on space.

* **predict_eproduction:** Predicts harvest of the target species, returns a data.table

* **predict_etargeting:** predicts targeting, returns a data.table.


* **get_random_draw_tripsDT:** for each vessel-day (id) randomly selects a choice (spstock2) based on prhat. Reworked to  data.table

* **get_reshape_catches:** Aggregates the catch from the day's trips to the fleet level.

* **get_reshape_landings:** Aggregates the landings from the day's trips to the fleet level.


* **joint_adjust_allocated_mults:** Adjusts the joint production multipliers for the allocated multispecies stocks
* **joint_adjust_others:** Adjusts the joint production multipliers for other stocks


* **zero_out_closed_areas_asc_cutout:** Closes a fishery and redistributes the probability associated with that stock to the other options.  This is based on the "stockarea_open" logical column.   Skips math if all stocks are open

* **get_reshape_targets_revenues:** A small "helper" function to reshape targets and revenues.

* **get_predict_quota_prices:** A function that uses exogenous data (average quarterly (live) prices of fish, proportion_observed) and endogenous data (quota remaining and fraction of quota remaining) to predict quota prices.  

There are few files in "scratch/econscratch" that may be useful
* **test_predict_etargeting_and_production.R :** was used to verify that the predict_etargeting.R and predict_eproduction.R functions works properly. It runs as a standalone and might be fun to explore. 

* **test_econ_module.R :**  is a test economic module. The last part is incredibly janky, but should just about close the bio$\rightarrow$ econ $\rightarrow$ bio loop. I'm just waiting to have runSim.R reordered before I can use it to write out F_full to stock[[i]] for the modeled stocks.  Pieces of this will be put into fragments that are called by "runSetup.R" (perhaps with an if cut-out for EconomicModel) because they only need to be run once.  Other parts should be converted into a function or many functions.



Obsolete
These are obsolete and have been moved to /scratch/econscratch/obsolete
* **get_at_age_stats, get_catch_at_age, get_e_smear, test_get_at_age_stats, test_get_catch_at_age, test_predict_eproduction:** all probably are obsolete and have been moved to /scratch/econscratch/obsolete.
* **get_random_draw_trips:** for each vessel-day (id) randomly selects a choice (spstock2) based on prhat
There are a few files in "/preprocessing/economic/"  These primarily deal with converting data from stata format to RData and making the estimated coefficients "line up" with the data.  There is also a helper file to wrangle the historical catch limit and catch data.   
* **zero_out_closed_asc:** Closes a fishery and redistributes the probability associated with that stock to the other options.
* **speed_asclogit:** Speed testing for an asc logit.

* **predict_eproductionCpp:** A version that uses RCpp sugar. This wasn't faster than base R.  I think this is because each "day" is a relatively small dataset.  Predicts harvest of the target species, returns a data.table

* **predict_etargetingCpp:** A version that uses RCpp sugar. This wasn't faster than base R.  Predicts targeting, returns a data.table.

* **get_best_trip:** for each vessel-day (id) selects the choice (spstock2) with the highest prhat. Obsolete and should be removed.

* **zero_out_closed_asc_cutout:** Closes a fishery and redistributes the probability associated with that stock to the other options. This is based on the "underACL" logical column.   Skips math if all stocks are open.  This is obsolete because the underACL logical is always equal to the stockarea_open, regardless of how we are modeling closures.

## Pre-processing Code
A bunch of pre-processing is needed to go from the stata econometric output and data to R data.tables.  Part 1  is written in Stata .do files.  The rest is written as R scripts files. Sorry 

### Stata preprocessing code
To run, you'll need to set the global MSEprojdir to the location of the project. Min-Yang's (on windows) is:

```
global MSEprojdir "C:\Users\Min-Yang.Lee\Documents\groundfish-MSE\"
```

You'll also need to put your data files into \${MSEprojdir}\\data\\data_raw\\econ. If you don't make any changes, some intermediate outputs will stay in this folder and any "final" outputs will go into: \${MSEprojdir}\\data\\data_processed\\econ



* **wrapper_common.do** This is a wrapper to process some inputs that is common to all economic scenarios.  Many global macros are set here to control what other files subsequently do.

* **wrapper_CF.do, wrapper_MSE.do, wrapper_validation.do ** Versions of data processing for the counterfactual data, MSE, and validation data.  All of the wrappers run the stata code --you may want to change a few global macros that define which files are which. Many global macros are set here to control what other files subsequently do.


* **asclogit_coef_export.do** This exports the stata estimates to csv.
* **econ_data_split.do** splits and renames multi-year datasets into single year datasets.

* **stocks_in_model.do** This makes a 1 column dataset of spstock2.  
* **recode_catch_limits.do** A little cleanup and conforming of the catch limit csv.
* **price_prep.do** : Construct output prices at the spstock2-date-post level and input prices at the hullnum-spstock2-date-post level.  Quota prices are at the hullnum-spstock2-month-post level, but stored with the other input prices.  Quota prices may vary by hullnum because some vessels are DAS scallopers and others are IFQ scallopers.  Note -- right now, we are only have Post period prices ready. All simulations are currently using 2010-2015 prices.
* **multiplier_prep.do** : Construct multipliers at the hullnum-spstock2-month-post level.  
* **quota_price_coef_export.do** : export the results of the "coverage" models of quota prices to text files.
* **quota_price_data_export.do**: export the exogenous independent data needed to simulate quota prices.   
Outputs of these are:

1. Four files containing asc logit coefficients corresponding to each gear and time period.

    a.  asclogit_gillnet_post_coefs.txt
    a.  asclogit_trawl_post_coefs.txt
    a.  asclogit_gillnet_pre_coefs.txt
    a.  asclogit_trawl_pre_coefs.txt

2.  Files containing catch limits.  We might want to simulate at the actual catch limits or a particular year.  
    a.  catch_limits_2010_2017.csv - the catch limits for 2010-2017
    a.  catch_limits_2017.csv - just the 2017 catch limits
    a.  annual_sector_catch_limits.csv - the catch limits averaged over 2010-2017

3.  A small dataset of spstock2 names: stocks_in_choiceset.dta.  I'm not sure what this is used for. 

4.  Text files containing the linear and exponential quota price model coefficients 
    a.  quota_price_exponential.txt
    a.  quota_price_linear.txt
5. A small dataset (quarterly_prices_${vintage_string}.csv) containing the indpendent variables needed to simulate quota prices.


### R preprocessing code


* **pre_process_econ_MSE.R:** This is a wrapper to finish processing data for the MSE type simulation.  This has been tested to work on a "data_for_mse" dataset.

* **pre_process_AB_validation.R:** This is a wrapper to finish processing data for the "validation simulations".  You will may need to change paths to directories.  We set all the input and output filenames here.  This has been tested to work on a "POSTasPOST" dataset.

* **pre_process_AB_counterfactual.R:** This is a wrapper to finish processing data for the Counterfactual type simulation.  This has been tested to work on a "data_for_mse" dataset.  Notably, quota prices are zeroed out for the Groundfish stocks.


* **import_day_limits.R** Imports day limits data, which is added to the simulation datasets 
* **targeting_coeff_import.R** converts the results of asclogit_coef_export to an R data.table
* **production_coefs.R** imports the targeting regression coefficients to an R data.table
* **input_price_import.R** imports and saves data.tables containing input prices
* **output_price_import.R** imports and saves data.tables containing output prices
* **multiplier_import.R** constructs vessel 
* **targeting_data_import.R** constructs the simulation datasets.  There are the "data" is joined to coefficients, prices, and multipliers using various combinations of "hullnum", "MONTH" , "spstock2", "doffy" (day of groundfish fishing year), "gearcat".  Note that because the data loops through "gffishingyears", we do not join on gffishingyear. This piece of code also computes average multipliers in the pre-period for the counterfactual sims.
* **quota_price_coefs.R**: Code to convert the coefficients in text files to a .Rds.
## Input Data
There are a few input datasets needed to run. 
Anna generates these:

data_processed/econ

annual_sector_catch_limits.csv

catch_limits_2010_2017.csv

catch_limits_2017.csv

stocks_in_choiceset.dta



data_raw/econ

trip_limits_forsim.dta 

reshape_multipliers.dta

production_regs_actual_pre_forR.txt

production_regs_actual_post_forR.txt

*.ster 

output_price_series*.dta

input_price_series*.dta

asclogit*.txt

POSTasPOST*.dta

* **STUB**: can be "CF", "MSE", or "valid" 
* **TIME**: can be "pre" or "post" 


* **STUB_TIMEMODELYYYY.Rds** - contains "independant variables" associated with the production and targeting models, estimated coefficients. Each row corresponds a vessel-day-targeting choice.  I tried to optimize for less memory usage, but it makes the model run extremely slowly.  

* **STUB_TIME_input_prices.Rds** vessel-day level input prices. fuelprice and crew wages vary by vessel.  This variability is partially due to their locations (prices of fuel vary by state; so do prices of labor). Also varies based on the size and composition of the boat's crew.  

* **STUB_TIME_output_prices.Rds**  day-level output prices that are gearcat specific. They are gearcat specific because the mix  of "other" varies by gearcat.   

* **STUB_TIME_multipliers.Rds**  These are vessel specific coefficients that scale landings of a target species to catch/landings of other (non-target) species that are used for simulating the pre catch-share period. POST can be "pre" or "post" and STUB can be "CF", "MSE", or "valid" 



I've been making small changes to mproc_test.txt and the "set_om_parameters_global.R" file.  The set_om_parameters_global.R contains things like file/folder locations, stocks that are in the model, and the RHS variables for the simulations.



### Outputs
We're retaining catch, landings, value, and quota_charges at the "hullnum-day-spstock2" level for the chosen primary target.  We are *not* retaining "hullnum_day" where the vessel chooses "no fish".  This saves space.

* **c_<spstock2>**: catch of spstock2
* **l_<spstock2>**: landings of spstock2
* **r_<spstock2>**: revenue (prices*landings) derived from spstock2

We also have identifiers for replicate (r), month (m), simulation year (y), and "year" (year).  year is the fishing year.

These can be pulled into stata with "postprocessing/economic/import_econ.do"


### To do and known bugs

* **runEcon_module.R :** 
  * Needs to be cleaned up.  Uses about 7-8gb.
  * Needs to be sped up.
    * The tidyverse version took approx 48sec/yr.
    * The revised data.table version takes 19 seconds/yr (depending on how often fisheries are closed). I should probably profile the code to speed it up.
    * I tried rewriting the model to economize on memory by only loading "small" data.tables and then mergeing them. That actually takes a large amount of time (>2-3 minutes). 
  * slowest parts are joint_production, zero-ing out the closed stocks, and the randomdraw.
  
### Notes
* packages are gmm, mvtnorm, tmvtnorm, expm, msm, Matrix, TMB, forcats, readr, tidyverse, dplyr, data.table
* the targeting and production datasets now conform. Production dataset is not necessary.

 * The Econ module is mostly written using data.table. 
 

[Return to Wiki Home](https://github.com/lkerr/groundfish-MSE/wiki)
