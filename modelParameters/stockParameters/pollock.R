# Scalar to Fmsy and sd for F before the management period begins. Distribution is lognormal. SD is lognormal SD.                                              
burnFmsyScalar <- 1.5
burnFsd <- 0.5

# first age and plus age
fage <- 1
page <- 9

#### Life history parameters ####

# length-at-age parameters -- see get_lengthAtAge for including covariates
laa_par <- c(Linf=108, K=0.16, t0=-0.44, beta1=0)
laa_typ <- 'vonB'

# weight-length parameters
waa_par <- c(0.00000743, 3.09) 
waa_typ <- 'aLb'
waa_mis<- FALSE

# maturity-length parameters
mat_par <- c(0.1636, 50.9967) 
mat_typ <- 'logistic'

# natural mortality
M <- 0.2
M_typ <- 'const'
init_M <- 0.2 #same for M = 0.2 and M-ramp scenarios
M_mis<- FALSE

# initial numbers at-age parameters
initN_par <- c(nage = page, N0 = 2e5, F_full = 0.05, M = M)
initN_type <- 'expDecline'

# Recruitment 
##HS with all recruitment values (what is used in stock assessment projections)##
##Could not find a SSB hinge point in the assessment report materials##
Rpar <- c(SSB_star = 0, 
          cR = 1,
          Rnyr = 20) # dont need to convert
R_typ <- 'HS'
R_mis<-FALSE
Rpar_mis <- c(SSB_star = 0, 
              cR = 1,
              Rnyr = 20)
#### Fishery parameters ####

# fishery and survey catchabilities
qC <- 0.0001
qI <- 0.0001

DecCatch<-FALSE #If survey catchability decreases with temperature, set to TRUE.


# fishery selectivity
# ### change select to L50 paramaterization like maturity
selC <- c(s0=0.03645717,s1=0.06016626,s2=0.09265774,s3=0.13423546,s4=0.24148544,s5=0.48153900,s6=1.00000000,s7=0.94751736,s8=0.19443504)
selC_typ <- 'input'

#Rpar <- c(h = 0.94,
#          R0 = 24198,
#          c = -0.540,            #update
#          SSBRF0 = 0.01972,      #update
#          sigR = 0.4,
#          beta3 = -2.501400e-01) #update

#R_typ <- 'BHSteep'

#### Survey parameters ####

## Survey information
# slxI <- matrix(1, nrow=nyear, ncol=nage)
selI <- c(1)
selI_typ <- 'const'
timeI <- 0.5 # when is the survey (as a proportion of the year)

#Rescale for the economic trawl survey. This is a scalar that is multiplies the simulated trawl survey so that it produces results comparable to the average of the spring and fall 2005-2019 bottom trawl survey.
# This was eyeballed based on these parameters:  selI=1, selI_typ=const,qI = 0.0001. So if these change, the rescale parameter should also change.
trawl_to_econ_multiplier<-1/15



#### Stock assessment model parameters ####

# number of years in assessment model
ncaayear <- 30

# Expansion range for setting limits on parameter bounds
boundRgLev <- 1.5

# CV for starting values for the assessment model
startCV <- 1.5

# scalar to bring pop numbers closer to zero (necessary
# for model fitting)
caaInScalar <- 1000  


#### Error parameters ####

# observation error levels
oe_sumCW <- 0.05
oe_sumCW_typ <- 'lognorm'
oe_paaCN <- 1000
oe_paaCN_typ <- 'multinomial'
oe_sumIN <- 0.2
oe_sumIN_typ <- 'lognorm'
oe_paaIN <- 1000
oe_paaIN_typ <- 'multinomial'
oe_effort <- 0.01
oe_effort_typ <- 'lognorm'

# process error levels  ###################################  !!!!!!!!!!!!!!
pe_R <- 0.5
pe_RSA <- 0.5 #stolen from cod, find values from stock assessment
pe_IA <- 0.18
  
# Implementation Error
## implementation error of fishing mortality
ie_F <- 0
ie_typ <- 'lognorm'
ie_bias <- 0 # % bias in implementation error


## implementation error of Catch Limit (iecl)
### Very few observations, baseline case is a uniform implementation error is uniformly distributed between  the upper (iecl_upper) and lower bounds (iecl_lower)
### These are parameterized using the pre-catch share time period.
### Catch=ACL*(1+iecl).  A random draw where iecl=0 <--> Catch=ACL.
# See /preprocessing/economic/readin_older_catchHist.do and compute_catch_limit_deviations.do

iecl_type<-'uniform'
iecl_upper<- .0695
iecl_lower<- -0.4602



# Observation bias (1 is no bias, 0.9 is a -10% bias, etc.)
ob_sumCW <- 1
ob_sumIN <- 1

#### -- Errors and warnings -- ####
if(1.0 %in% c(qI, qC)){
  stop('catchability (qI and qC) must not be exactly one (you can make it
        however close you want though')
}
