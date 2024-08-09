
# Run simulation setup. This is a separate file so that the model setup
# parameters can later be accessed by running the setup but not the
# entire simulation.

# load all the functions
ffiles <- list.files(path='functions/', pattern="^.*\\.R$",full.names=TRUE, recursive=TRUE)
invisible(sapply(ffiles, source))

# Get the result directory path
source('processes/identifyResultDirectory.R')

# Load the overall operating model parameters
source('modelParameters/set_om_parameters_global.R')


# get the operating model parameters -- first search the space for every
# version of the set_stock_parameters_xx files and put them in this list.
fileList <- list.files('modelParameters/stockParameters', full.names=TRUE)
if(!is.null(stockExclude)){
  stockExclude <- paste0(stockExclude, '.R')
  rem <- match(stockExclude, basename(fileList))
  if(any(is.na(rem))){
    stop(paste('run_setup.R: check names of excluded stocks in', 
          'set_om_parameters_global file and be sure they match the actual', 
          'stock file names'))
  }
  fileList <- fileList[-rem]
  if(length(fileList) < 1){
    stop(paste('run_setup.R: check names of excluded stocks in', 
               'set_om_parameters_global file. It looks like you have',
               'removed all available stocks.'))
  }
}

# Retrieve the stock names from the file paths
stockNameListExt <- sapply(fileList, basename)
stockNameList <- unname(sapply(stockNameListExt, sub, 
                               pattern='\\.R$', replacement=''))

nstock <- length(fileList)
stockPar <- as.list(nstock)
for(i in 1:nstock){
  tempEnv <- new.env()
  source(fileList[[i]], local = tempEnv)
  # Calculate number of ages (needed for other variables)
  tempEnv$nage <- length(tempEnv$fage:tempEnv$page)
  # Add name of stock for labeling objects and plots
  tempEnv$stockName <- stockNameList[i]
  stockPar[[i]] <- as.list(tempEnv)
  rm(tempEnv)
}

# Get the names of each stock (stocks must follow naming convention)
stockNames <- unname(sapply(fileList, function(x) 
                strsplit(x, 'stockParameters/|\\.R')[[1]][2]))



# Get the run info so the functions work appropriately whether they are
# on Windows or Linux and whether this is an HPCC run or not.
source('processes/get_runinfo.R')

# load the required libraries
source('processes/loadLibs.R')


# load the list of management procedures
source('processes/generateMP.R')

# Model structure (includes loading in temperature data)
source('processes/genAnnStructure.R')

# Load specific recruitment functions (these are a list for simulation-based 
# approach to deriving Bproxy reference points
source('processes/Rfun_BmsySim.R')

# Load default ACLs and fractions of the ACL that are allocated to the catch share fishery
source('processes/genBaselineACLs.R')

#Input data location for economic models
econdatapath <- 'data/data_processed/econ'

                            # Reults folders for economic models. Create them if necessary
econ_results_location<-"results/econ/raw"
dir.create('results/econ/raw', showWarnings = FALSE, recursive=TRUE)
dir.create('results/sim', showWarnings = FALSE, recursive=TRUE)
dir.create('results/fig', showWarnings = FALSE, recursive=TRUE)

# If running on a local machine, more than one repetition should be
# used otherwise some plotting functions (e.g., boxplots) will fail
if(runClass == 'Local' && nrep == 1){
  # stop('For local runs please set nrep > 1 (in set_om_parameters.R)',
       # call.=FALSE)
  nrep <- 2
  warning('local run: nrep (in set_om_parameters.R) set to 2 to avoid errors')
}

# # Warning regarding Bmsy calculation hindcasts
# tst <- !is.na(mproc$BREF_TYP) & 
#        mproc$BREF_TYP == 'SIM' &
#        mproc$RFUN_NM == 'hindcastMean' &
#        mproc$BREF_PAR0 > ncaayear
# if(any(tst)){
#   msg <- paste0('Number of years in hindcast that you specified (', 
#                 mproc$BREF_PAR0[tst], ') is larger than the number of years in', 
#                 ' the moving window of the stock assessment model (', 
#                 ncaayear, '). Number of years used in the hindcast changed to ', 
#                 ncaayear, '.\n')
#   warning(msg)
# }

# Error regarding bad combinations of mproc
tst <- mproc$BREF_TYP == 'RSSBR' & mproc$RFUN_NM == 'forecast'
if(!all(is.na(tst)) && any(tst & !is.na(tst))){
  stop(paste('In mproc BREF_TYP and RFUN_NM cannot be RSSBR and forecast,',
             'respectively. While this may be possible to compute it seems',
             'odd to use future SSB in the calculation of R for R*SSBR',
             'but then not include SSB projections when thinking about what',
             'the reference point should actually be.'))
}

# Error regarding number of years.
inTest <- (plotBrkYrs + fmyearIdx) %in% (fmyearIdx+1):nyear
if(!all(inTest)){
  stop(paste('check plotBrkYrs in set_om_parameters_global. One or more',
             'of your break years is outside the possible range.'))
}

# Error test that the HCRs supplied are actually coded up in get_nextF()
stopifnot("An HCR supplied by mprocfile is not recognized"=tolower(mproc$HCR) %in% 
  c('slide','sliderebuildaware','simplethresh','simplethreshrebuildaware',
    'constf','constfrebuildaware','step'))


# get all the necessary containers for the simulation
stockCont <- list()
for(i in 1:nstock){
  stockCont[[i]] <- get_containers(stockPar=stockPar[[i]])
}

# Combine the stock parameters and the stock containers into a single list
stock <- list()
for(i in 1:nstock){
  stock[[i]] <- c(stockPar[[i]], stockCont[[i]])
}
names(stock) <- stockNames


# Set up a container dataframe for Fleet-level Economic Results
# These are simulation specific so they are stored in a single dataframe
source('processes/genEcon_Containers.R')


# Ensure that there are enough initial data points to support the
# index generation at the beginning of the model.
mxModYrs <- max(sapply(stock, '[[', 'ncaayear'))
if(fyear < mxModYrs){
  stop(paste('fyear is less than the maximum number of years used',
             'for assessment for one of the stocks (ensure that fyear',
             'in the global parameters file is less than ncaayear for',
             'each stock'))
}

if (platform == 'Linux'){
  if(!file.exists('../EXE/ASAP3.EXE')){
    warning(paste('ASAP3.EXE should be loaded in a directory EXE in the parent',
               'directory of groundfish-MSE -- i.e., you need an EXE',
               'directory in the same directory as Rlib and EXE must contain',
               'ASAP3.EXE', sep='\n'))
  }
  rand <- sample(1:10000, 1)
  tempwd <- getwd()
  rundir <- paste(tempwd, "/assessment/ASAP/Run", '_', rand, sep = "")
  dir.create(path = rundir)
  from.path <- paste('../EXE/ASAP3.EXE', sep = "")
  to.path   <- paste(rundir, sep= "")
  file.copy(from = from.path, to = to.path)
  
}

