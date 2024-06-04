


# Options for management procedures
### Sam Truesdell (struesdell@gmri.org)
### Mackenzie Mazur (mmazur@gmri.org)
Management procedures are specificed in a csv located in the folder "modelParameters."  The filename is passed in using the object "mprocfile" which is defined in set_om_parameters_global.R

This documentation describes what to write in the mproc.csv file and what it means.

## ASSESSCLASS
Refers to the class of assessment model. Options are:

* **CAA**: A catch-at-age model. Currently written in TMB but planning additional option for ASAP-based version.

* **PLANB**: Index-based approach. This version uses Chris Legault's apply_PlanBsmooth() function. More information on that can be found here: [groundfish-MSE/documentation/planBdesc.md](documentation/planBdesc.md).

* **ASAP**: Age-Structured Assessment Program (Legault & Restrepo 1998). This stock assessment model is currently used for the majority of analytical groundfish stock assessments in the region. 

## HCR
Refers to the shape of the harvest control rule. Options are:

* **constF**: A ‘constant fishing mortality’ HCR harvests the same fraction of the stock regardless of biomass, and consequently catch increases linearly with abundance (e.g., 75% FMSY; Restrepo et al., 1998; Goodman et al., 2002). The catch is set equal to a fixed proportion of the estimate of the population size. This option provides a balance between constant catch and constant escapement HCRs, as this option responds to stock size (Punt, 2010). Variants of this HCR could be based on different precautionary buffers (Restrepo et al., 1998). Constant F HCRs have been applied in the management of the U.S. west coast groundfish fishery (Dichmont et al., 2016) and the New Zealand orange roughy fisheries (Doonan et al., 2014). 

Status in New England groundfish management: This option (75% FMSY) is the Acceptable Biological Catch (ABC) control rule for many stocks that had not rebuilt on the expected schedule. 

* **simplethresh**: A ‘threshold’ HCR harvest changes target F as a simple step function of stock biomass, with F set to zero at a level of abundance (e.g., 50%SSBMSY; Punt, 2010). Variants of this HCR could be based on different biomass thresholds (Deroba et al., 2019; Feeney et al., 2019). Threshold HCRs have been applied in management of whales by the International Whaling Commission (Butterworth and Best, 1994). 

Status in New England groundfish management: This option has not been implemented.

* **slide**: A sliding control rule.  Similer to simplethresh, except when the estimated SSB is lower than the SSB reference point fishing is reduced though not all the way to zero. Instead, a line is drawn between [SSBRefPoint, FRefPoint] and [0, 0] and the advice is the value for F on that line at the corresponding estimate of SSB.

* **pstar**: The P* method. The aim of this HCR option is to avoid overfishing by accounting for scientific uncertainty with a probabilistic approach. In this scenario, the P* approach (Prager & Shertzer, 2010) is used to derive target catch. The P* method derives target catch as a low percentile of projected catch at the OFL, to allow for scientific uncertainty. The distribution of the catch at the OFL was assumed to follow a lognormal distribution with a CV of 1 (Wiedenmann et al., 2016). The target catch will correspond to a probability of overfishing no higher than 50% (P* <0.5) in accordance with the National Standard 1 guidelines. This option emulates HCRs used in many other Councils in the United States, such as the Mid-Atlantic Fishery Management Council (MAFMC). 

* **step**: Step in fishing mortality. If the SSB decreased below the biomass threshold, this HCR uses a target F of 70% FMSY that has recently been applied to New England groundfish as a default Frebuild. If the SSB never decreased below the biomass threshold or increased to over SSBMSY after dropping below the biomass threshold, this HCR uses a target F at the F threshold. This alternative directly emulates an HCR used for some New England groundfish. National Standard Guidelines were amended in 2016 and these revisions reduced the need to identify an incidental bycatch ABC and indicated that Frebuild need not be recalculated after every assessment, making it less likely that Frebuild will be set to zero in response to short-term lags in rebuilding.

* **NA**: A possible value for situations where there is no harvest control rule (e.g., if using a planB assessment method -- that method gives catch advice directly).


## FREF_TYP
Refers to the method for developing the F reference point (i.e., a proxy for F<sub>MSY</sub>).  Options are:

* **YPR**: Use yield-per-recruit methods to develop the F<sub>MSY</sub> proxy. Yield-per-recruit provides an F estimate that maximizes yield given growth rate, a selectivity pattern and natural mortality-at-age. Assumes constant recruitment.

* **SPR**: Use spawning potential ratio methods to develop the F<sub>MSY</sub> proxy. Spawning potential ratio depends on estimates of spawner biomass-per-recruit models. Those models assume natural mortality, growth and maturity schedules to determine the level of fishing mortality that results in a given level of average spawner biomass-per-recruit. Spawning potential ratio models take the levels of spawner biomass-per-recruit and standardize them to the maximum (i.e., the level at F=0).  This way the reference points that are developed are comparable among stocks that have different life histories. Spawning potential ratio matches a level of fishing mortality with a given ratio of spawner biomass-per-recruit at that level of fishing mortality relative to spawner biomass-per-recruit at zero fishing.

* **Fmed**: ICES approach that translates average recruitment-per-spawner to a value on the spawner biomass-per-recruit curve to determine the F<sub>MSY</sub> proxy reference point. This approach has not worked particularly well so far because mean recruitment is so variable. Fmed does not require additional parameters (i.e., FREF_PAR0 should be set to NA).

* **FmsySim**: Use simulation to determine F<sub>MSY</sub>; in other words try a set of candidate values for F, run a projection, and at the end of that process determine which value for F maximized yield.

* **NA**: A possible value for situations where there is no harvest control rule (e.g., if using a planB assessment method -- that method gives catch advice directly).

## FREF_PAR0
Refers to the parameters necessary for developing the F<sub>MSY</sub> proxy. These are presented here as linked to the reference point types above.

* **YPR**: The value that represents *x* percent of the slope at the origin. Definitely the most common entry here will be 0.1 (for 10%), which will give the reference point F<sub>0.1</sub>. You have thought pretty hard about this if you are using something other than 0.1 here.

* **SPR**: The value representing the desired quotient of spawning biomass-per-recruit at the reference point to spawning biomass-per-recruit at zero fishing. A value of 0.4 (corresponding to F<sub>40%</sub>) would indicate that F should be set at a level that represents 40% survival relative to F=0. Note that **0.4** is what you write in the file for F<sub>40%</sub> (i.e., the proportion rather than percentage).

* **Fmed**: Fmed does not require additional parameters so FREF_PAR0 should be set to NA.

* **FmsySim**: The parameter value if using FmsySim is related to how recruitment should be treated. If the recruitment function is *hindcastMean* this will represent how many years to look back into the past for this calculation. For example, if the value is set to 10, recruitment in each year of the projection that is used to generate F<sub>MSY</sub> will be the average of the (assessment model-estimated) previous 10 years of recruitment. If the recruitment function is *forecast*, this parameter represents the number of years to look into the future when running the simulation. Each year in the future will use the projected recruitment for that year (including temperature effects if they are switched on).

* **NA**: A possible value for situations where there is no harvest control rule (e.g., planB) or the reference point does not require a parameter (e.g., F<sub>MED</sub>).

## FREF_PAR1

* **For YPR**: Does not require additional parameters; should be NA.

* **For SPR**: Does not require additional parameters; should be NA.

* **For Fmed**: Fmed does not require additional parameters so FREF_PAR0 should be set to NA.

* **For FmsySim**: If RFUN_NM is *hindcastMean* this should be the most recent year to use the the backward-looking projection. In most cases this will be *-1* to indicate that the projection should go all the way to the previous year. Other values are possible if testing issues related to assessments that are not updated frequently.  If RFUN_NM is *forecast* then this should be NA.

* **NA**: A possible value for situations where there is no harvest control rule (e.g., planB).


## BREF_TYP
Methods for determining the SSB<sub>MSY</sub> proxy.

* **RSSBR**: SSB<sub>MSY</sub> will be the level of spawning biomass-per-recruit at the F<sub>MSY</sub> proxy multiplied by "average" recruitment. Average recruitment is determined by the values provided under *RFUN_NM* and *BREF_PAR0*. Only the *hindcastMean* option is available with this reference point method because forward-looking methods to derive recruitment (that depend on temperature) would also imply using forward-looking methods for spawner biomass which RSSBR does not do.

* **SIM**: SSB<sub>MSY</sub>  developed via simulation. Projections are carried forward for *n* years (which is indicated in BREF_PAR0) and at the end of that period the mean SSB will be used as the SSB<sub>MSY</sub> proxy.  If *forecast* is used as the recruitment function then temperature will be included in the projections (if it is switched on).

* **NA**: A possible value for situations where there is no harvest control rule (e.g., planB).


## BREF_PAR0
Refers to the parameters necessary for developing the B<sub>MSY</sub> proxy. These are presented here as linked to the reference point types above.

* **For RSSBR**: The value entered is the number of years to look back in a hindcast recruitment function. For example, if the value is 10 the average recruitment that will be used would be the average (assessment model-estimated) recruitment over the previous 10 years.

* **For SIM**: This parameter has options depending on the type of recruitment function that is used. If the *hindcastMean* recruitment function is used then it represents the number of years over which the average is calculated (see example in previous entry for RSSBR). If the *forecast* recruitment function is specified the parameter represents the number of years that will be averaged over in the forecast simulation (which involves temperature if that functionality is switched on).

* **NA**: A possible value for situations where there is no harvest control rule (e.g., planB).

## BREF_PAR1
Refers to the parameters necessary for developing the B<sub>MSY</sub> proxy. These are presented here as linked to the reference point types above.

* **For SIM**: If RFUN_NM is *hindcastMean* this should be the most recent year to use the the backward-looking projection. In most cases this will be *-1* to indicate that the projection should go all the way to the previous year. Other values are possible if testing issues related to assessments that are not updated frequently.  If RFUN_NM is *forecast* then this should be NA.

* **NA**: A possible value for situations where there is no harvest control rule (e.g., planB).


## RFUN_NM
The type of recruitment function to be used. Currently all options involve Beverton-Holt curves but this is easily expanded if desired.

* **forecast**: Recruitment in any simulations for the development of F<sub>MSY</sub> or B<sub>MSY</sub> reference points will be calculated based on a forecast. In each year of the simulation, expected recruitment will be calculated (with a temperature effect if that switch is turned on). At the end of the *n*-year projection period (where *n* is specified under FREF_PAR0 or BREF_PAR0) the value for the F or B reference points is calculated according to the specifications given under those columns in *mproc.csv*.

* **hindcastMean**: Recruitment in each year of a simulation is based on a set of previous recruitments (recruitment values are outputs from assessment models). The function simply returns the mean recruitment over the number of years specified under the parameterization in FREF_PAR0 or BREF_PAR0.


## RPINT
The frequency with which reference points are re-calculated.

* The value represents the frequency. For example, if the value is 3, reference points are recalculated every 3 years. In the years when the reference points are not updated the advice may change based on an updated assessment model but the reference points (and thus the shape of any associated harvest control rule) remains the same.

## AssessFreq
The frequency with which the stock assessment is conducted. 

* The value represents the frequency. For example, if the value is 3, the stock assessment is conducted every 3 years. In the years when the stock assessment is not conducted, the advice is based on the most recent stock assessment. 

## ImplementationClass
This sets harvesting to be determined by a "StandardFisheries" or "Economic" submodel. This column is only used in (variations of) the runSim.R file.

## projections
This determines if projections are used or not. If set to TRUE, projections are used. When projections are used, catch advice is  generated from the projected catch with F determined from the HCR. There are 100 iterations for each projection and uncertainty in recruitment and the initial population number, which was the estimated number in the last year of the assessment. Initial population number was drawn from a lognormal distribution with a mean of the final population number estimatel. Projections are currently used in determining catch advice for some New England groundfish. 

## rhoadjust
This determines if rho-ajdustments are used or not. If set to TRUE, rho-adjustments are used. Due to the retrospective patterns apparent in New England groundfish stock assessments, this scenario incorporated rho-adjustments using Mohn’s Rho values (Mohn, 1999). A rho-adjustment has been applied to all analytical New England groundfish NEFSC stock assessments, except for GOM cod. This stock assessment scenario option evaluates the effect of a rho-adjustment on the fishery outcomes. If projections are used, rho-adjustments are also applied to the abundance, recruitment, and fishing mortality estimates used in projections.  

## mincatch
This determines if a minimum catch constraint is used in catch advice or not. If set to TRUE, a minimum catch constraint is used. Due to the low stock sizes in many of the groundfish fisheries, some HCRs would likely create extremely low catches for some fisheries. A a minimum catch limit prevents F from declining close to zero. 

## varlimit
This determines if a catch variation limit is applied to the catch advice. If set to TRUE, a catch variation limit is applied. The aim of this option is to provide catch stability if stock biomass were to substantially change from year to year. Stable catch was identified as an objective in the Council’s risk policy (NEFMC 2016). This option prevents the current year’s catch limit from changing more than 20% from the previous year’s catch limit. However, catch is constrained so that it will not be higher than the OFL.

# Economic Options
The following are only relevant if *ImplementationClass*=='Economic.'

## EconName
A short name for the scenario.  This column is not used by any of the simulation code.  It is mostly as a convenience but is also somewhat duplicative with the EconData column and probably should be removed.

## EconType
The broad type of fisheres management.  This column is only used in the ``joint_adjust_allocated_mults.R`` function.  The two values allowed here are "Multi" and "Single."

* **Multi**: a closure in a stockarea closes all groundfish in that stockarea (no landings of GB Cod if GB haddock is closed).  This resembles how the catch share fisheries is managed.
* **Single**: a closure in a stockarea does *not* close everything in that stockarea (landings of GB Cod allowed if GB haddock is closed).  This does not really resemble how the catch share fishery is managed.
   
## CatchZero
Governs catch if a stock is closed. This column is only used in the ``joint_adjust_allocated_mults.R`` function.

* **TRUE**: no catch of GB Cod if GB cod is closed.  This implies perfect targeting/avoidance.
* **FALSE**: catch of GB Cod occurs when GB cod is closed.  All catch would be discarded.  This implies no change in joint targeting behavior occurs if a stock is closed.

True behavior is somewhere in between these two extremes.  
  
## EconData
  A stub that determines which base economic dataset to use (see data processing steps).   This column determines the type of data loaded in ``/processes/loadEcon2.R.`` There are three "words" in this column, separated by an underscore. The first word describes the type of data.

* **validation**: This is data that set up to assess how well the economic model performs.  The econometric model is estimated on pre catch-share data.  The independent variables are set to their actual values in the post catch-share time period.  If the econometric model is good, then using pre catch-share data to predict post catch share behavior will work well.

* **counterfactual**: This is data that set up to assess how different the fishery would have been if there were no catch shares.  The econometric model is estimated on pre catch-share data.  The independent variables are adjusted to reasonable values corresponding to a days-at-sea fishery.  Differences between the counterfactual and the validation/actual are the due to the catch share policy. 

* **MSE**: This is data set up to perform best in the future. The econometric model is estimated on post catch-share data. The independent variables are set to their actual values in the post catch-share time period.  

The second word describes the time period used for the econometric model. It is a bit duplicative.

* **pre**: Econometric model from 2004-2009.
* **post**: Econometric model from 2010-2015.

The third word describes the type of econometric model. We estimated models with and without constants.  We estimated models with two types of constructions for the opportunity costs of fishing.

* **coefs1**: has alternative specific constants.  The price of a day-at-sea and an interaction between days-at-sea price  and vessel length enters the econometric model separately. The effects of these independent variables is allowed to vary across the different targeting choices.  
* **coefsnc1**: No alternative specific constants.   The price of a day-at-sea and an interaction between days-at-sea price  and vessel length enters the econometric model separately. The effects of these independent variables is allowed to vary across the different targeting choices.  
* **coefs2**:has alternative specific constants. The cost of a day at sea is subtracted from the expected revenues.  The price of a day at sea does not enter the estimating equation.
* **coefsnc2**:No alternative specific constants.The cost of a day at sea is subtracted from the expected revenues.  The price of a day at sea does not enter the estimating equation.

Model 2 fit the data as well as model 1 and is a bit more theoretically compelling.  The ``nc`` flavor is more general than the model with constants. So most simulations are the ``nc2`` flavor.  

## MultiplierFile
  The full name of the multiplier file to use.  Must  include the .Rds extension.  This column is used to load data in ``/processes/setupEconType.R`` 

* **MSE_post_multipliers.Rds** Multipliers set up for the MSE based on the post time period.

## OutputPriceFile 
  The full name of the output price  file to use.  Must include the .Rds extension.  This column is used to load data in ``/processes/setupEconType.R`` 

* **MSE_post_output_prices.Rds** Output prices set up for the MSE based on the post time period.

## InputPriceFile 
  The full name of the input price  file to use.  Must include the .Rds extension.  This column is used to load data in ``/processes/setupEconType.R`` 
  
* **MSE_post_input_prices.Rds** Input prices set up for the MSE based on the post time period.
  
## ProdEqn
  Suffix for the production equation. The valid production equations are described in ``set_om_parameters_global.R``.  Currently, the choices are just ``pre`` and ``post``.  This column is used to declare the production equation in ``/processes/setupEconType.R`` 
  
## ChoiceEqn
  Suffix for the choice equation. The valid choice equations are described in ``set_om_parameters_global.R``. Currently, there are 4 "pre" models and 1 "post" model:  


* **pre1**
* **pre2** 
* **prenc1**
* **prenc2** 
* **postnc2**

The MSE will use the postnc2.  
This column is used to declare the choice equation in ``/processes/setupEconType.R`` This is also in the economic model documentation.


## econ_year_style
This determines how we are passing in years of economic data
1. A year (YYYY, like 2015 or 2013). Every MSE year will use economic data from a single year
2. Randomly select a year  - each year of the MSE gets randomly matched with a year of economic data. This is done with replacement.
3. Block Randomly select a year - each year of the MSE gets randomly matched with a year of economic data. Each replicate will have the same economic year.
    # In Rep 1, if cal_year=2011 matches to econ_year=2012, then in Rep 2, cal_year=2011 will match to econ_year=2012.
4. Align. We align the 2010 economic data to the 2010 year of the simulation. We align 2011 economic data to the 2011 year of the simulation.  Once we run out of years of economic data, we start over at 2010.    




## ie_override
 A True or False column determines whether we will  override the ``ie_F`` and ``ie_bias`` parameters in the  defined in ``/stock/stockname.R`` and stored in ``stock[[N]]ie_F``


## ie_source

If ie_override=TRUE, this determines where to find updated parameters. This can either 
1.  "Internal" this reads in an internally estimated ie_F_hat and ie_bias_hat from a previously run model. 
2.  "results_YYYY-MM-DD-HH-MM-SS"  This reads in results from the omvalGlobal file in that folder. 

## ie_from_model
if ie_source=Internal, this determines the model number to use for updated parameters.



[Return to Wiki Home](https://github.com/lkerr/groundfish-MSE/wiki)
