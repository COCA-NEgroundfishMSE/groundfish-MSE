# Scalar to Fmsy and sd in F before the management period begins. Distribution is lognormal. SD is lognormal SD.
burnFmsyScalar <- 1 
burnFsd <- 0.3

# first age and plus age
fage <- 1
page <- 10

#### Life history parameters ####

# length-at-age parameters -- see get_lengthAtAge for including covariates
laa_par <- c(Linf=114.1, K=0.22, t0=0.17, beta1=0)
laa_typ <- 'vonB'

# weight-length parameters
waa_par <- c(exp(-11.6913), 3.0219) #SAW 55 p.659
waa_typ <- 'aLb'

# maturity-length parameters
mat_par <- c(0.127, 38.8) # O'brien GB cod female
mat_typ <- 'logistic'

# natural mortality
M <- 0.2
M_typ <- 'const'
init_M <- 0.2 #same for M = 0.2 and M-ramp scenarios

# initial numbers at-age parameters
initN_par <- c(nage = page, N0 = 2e7, F_full = 0.05, M = M)
initN_type <- 'expDecline'

# Recruitment
##HS with all recruitment values (what is used in stock assessment projections)##
Rpar <- c(SSB_star = 50000,
          cR = 1, Rnyr=20) # dont need to convert
R_typ <- 'HS'
#Rpar <- c(h = 6.630977e-01,
#          R0 = 6.087769e+07,
#          beta3 = -2.501400e-01,
#          SSBRF0 = 0.01972)
#R_typ <- 'BHSteep'

#### Fishery parameters ####

# fishery and survey catchabilities
qC <- 0.0001
qI <- 0.0001

DecCatch<-FALSE #If survey catchability decreases with temperature, set to TRUE.

# fishery selectivity
selC <- c(s0=5, s1=0.08)
selC_typ <- 'Logistic'

#### Survey parameters ####

## Survey information
# slxI <- matrix(1, nrow=nyear, ncol=nage)
selI <- c(1)
selI_typ <- 'const'
timeI <- 0.5 # when is the survey (as a proportion of the year)

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

# stock assessment misspecifications
M_mis<- FALSE
M_mis_val<-0.2
R_mis<- FALSE
Rpar_mis <- c(SSB_star = 6300, #the 'wrong' SRR parameters that will be used in BRP estimation and projections
cR = 1,
Rnyr= 20)
waa_mis<- FALSE

#### Error parameters ####

# observation error levels
oe_sumCW <- 0.05
oe_sumCW_typ <- 'lognorm'
oe_paaCN <- 100
oe_paaCN_typ <- 'multinomial'
oe_sumIN <- 0.2
oe_sumIN_typ <- 'lognorm'
oe_paaIN <- 100
oe_paaIN_typ <- 'multinomial'
oe_effort <- 0.01
oe_effort_typ <- 'lognorm'

# process error levels 
pe_R <- 5.839408e-01
pe_RSA<- 0.5 #recruitment process error assumed in the stock assessment
pe_IA <- 0.18


# Implementation Error
## implementation error of fishing mortality
ie_F <- 0
ie_typ <- 'lognorm'
ie_bias <- -0.13 #0 #-0.1 # % bias in implementation error
ie_bias <- -0 

## implementation error of Catch Limit (iecl)
### Very few observations, baseline case is a uniform implementation error is uniformly distributed between  the upper (iecl_upper) and lower bounds (iecl_lower)
### These are parameterized using the pre-catch share time period.
### Catch=ACL*iecl.  A random draw where iecl=1 <--> Catch=ACL.
# See /preprocessing/economic/readin_older_catchHist.do and compute_catch_limit_deviations.do
iecl_type<-'uniform'
iecl_upper<- 2.318
iecl_lower<- .3213


# Observation bias (1 is no bias, 0.9 is a -10% bias, etc.)
ob_sumCW <- 1
ob_sumIN <- 1






# catch observation bias (codCW + codCW*C_mult)
C_mult <-  0 #1.25 for bias, 0 for no bias

#### -- Errors and warnings -- ####
if(1.0 %in% c(qI, qC)){
  stop('catchability (qI and qC) must not be exactly one (you can make it
        however close you want though')
}
