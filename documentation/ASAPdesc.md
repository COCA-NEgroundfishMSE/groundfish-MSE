
# ASAP assessment documentation
### Ashley Weston (aweston@gmri.org)

<br> This is an overview of the ASSESSCLASS management procedure option
‘ASAP’ which utilizes the Age Structured Assessment Program (ASAP)
version 3. The full documentation and executable for this assessment
model can be found in the [NOAA Fisheries
Toolbox](https://www.nefsc.noaa.gov/nft/ASAP.html).

------------------------------------------------------------------------

### File Setup

Using the ASAP option assumes that you have 2 things (locally) in the
‘/asessment/ASAP’ folder:

* an ASAP.dat file with a given stock name. For example ‘codGOM.dat’, and either:
* he ASAP3.exe executable, or  
* a Linux ASAP3 executable. 

A Linux ASAP3 will need to be compiled from source.  These are the steps you'll need to take to run ASAP3 natively in Linux.
* Get ADMB. 
* Get the ASAP3 source code. Rename asap3.tpl to ASAP3.tpl
*  Use ADMB to compile ASAP3.tpl. See this [quick start](https://www.admb-project.org/downloads/admb-12.3/QuickStartLinux.html).
*  Update the full.path.to.asap in runSetup.R
*  Update the asapEst in get_ASAP.R


*This option can be run locally or on the HPCC. If running on the HPCC
the ASAP3.EXE should be in a folder called “EXE” on the same directory
level as groundfish-MSE.  It will be run using wine.*

### Functionality

The interaction between R and ASAP input/output files utilizes Chris
Legault’s **ASAPplots()** package in R

A new .dat file is created for each year the assessment is run in the
projection. The syntax is ‘stockname\_nrep\_yr.dat’

#### Model asusmptions

This option is meant to be a self-test where the assessment model and
operating model have the same structural assumption.

-   Weight-at-age and maturity-at-age are extracted from the operating
    model (currently time-invariant)
-   There is 1 fleet and 1 survey
-   Simulated data including catch-at-age, sum catch weight, survey
    catch-at-age, and sum survey numbers generated from the operating
    model are input to the .dat file for each year.
-   Catch effective sample size, catch CV, survey effective sample size,
    and survey CV are all extracted from the operating model

The ASAP executable is run and then the results are saved as an .Rdata
file with the same syntax as the .dat file for each year and simulation.


