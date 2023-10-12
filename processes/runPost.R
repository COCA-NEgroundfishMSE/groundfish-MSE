library(here)
here::i_am("processes/runPost.R")
# Get the result directory path
source(here("processes","identifyResultDirectory.R"))

# Get the run info so the functions work appropriately whether they are
# on Windows or Linux and whether this is an HPCC run or not.
# source(here("processes","get_runinfo.R"))
source(here("processes","runSetup.R"))

# Read in overall operating model parameters from the saved version
source(here(ResultDirectory,"set_om_parameters_global.R"))

#update mproc from the saved version

mproc <- read.csv(here(ResultDirectory, "fig",mprocfile), header=TRUE,
                  stringsAsFactors=FALSE)


# load all the functions
ffiles <- list.files(path='functions/', full.names=TRUE, recursive=TRUE)
invisible(sapply(ffiles, source))

# load the required libraries
source('processes/loadLibs.R')

# Load in the stock-level simulation results
fl <- list.files(file.path(ResultDirectory, 'sim'), pattern="omvalGlobal", full.names=TRUE)
flLst <- list()
for(i in 1:length(fl)){
  load(fl[i])
  flLst[[i]] <- omvalGlobal
  names(flLst[[i]]) <- names(omvalGlobal)
}


boxplot_these<-c("SSB", "SSB_cur", "R", "F_full", "sumCW", "annPercentChange", 
  "meanSizeCN", "meanSizeIN", "OFdStatus", "OFgStatus" ,
  "mxGradCAA", "sumEconIW","Gini_stock_within_season_BKS")
rp_these<-c("FPROXY", "SSBPROXY")

traj_these <- c("SSB", "SSB_cur", "R", "F_full", "sumCW", 
              "ginipaaCN", "ginipaaIN", "OFdStatus",
              "mxGradCAA",
              "relE_qI", "relE_qC", "relE_selCs0", "relE_selCs1",
              "relE_ipop_mean", "relE_ipop_dev",
              "relE_R_dev", "relE_SSB", "relE_N","relE_CW", "relE_IN",
              "relE_R", "relE_F", "OFgStatus",   #AEW
              "FPROXY", "SSBPROXY","sumEconIW","Gini_stock_within_season_BKS",
              "ACL", "F_fullAdvice")

SIMboxplot_these<-c("HHI_fleet","Shannon_fleet","Gini_fleet", 
                  "Gini_fleet_bioecon_stocks", "total_fleet_rev", "total_fleet_modeled_rev", "total_fleet_groundfish_rev")
SIMrp_these<-SIMboxplot_these
SIMtraj_these <-SIMboxplot_these



for(i in 1:length(flLst[[1]])){

  omval <- get_simcat(x=lapply(flLst, '[[', i ), along_dim=1)
  names(omval) <- names(flLst[[1]][[i]])
  stknm <- names(flLst[[1]])[i]
  
  # The "year" list element in omval is for plotting and needs to be
  # only the length of the number of years -- unlike the other categories
  # this doesn't change. So plotting doesn't get result in errors, change
  # the dimensions of this list element
  omval[['YEAR']] <- omval[['YEAR']][1:(length(omval[['YEAR']])/length(flLst))]
  
  dirOut <- paste0(ResultDirectory, '/fig/', stknm, '/')

  get_plots(x=omval, stockEnv = stockPar[[i]], 
            dirIn=file.path(ResultDirectory, "sim"), dirOut=dirOut, 
            boxnames=boxplot_these, rpnames=rp_these, trajnames=traj_these,breakyears=plotBrkYrs)
}


#Directory Setups for Simulation level figures
dirOut <- file.path(ResultDirectory, "fig", "simulation")
dir.create(here(dirOut), showWarnings=FALSE)

# Load in the aggregate simulation results
sl <- list.files(file.path(ResultDirectory, "sim"), pattern="simlevelresults", full.names=TRUE)
simlevel <-list()

if(length(sl)==1){
  simlevel<-readRDS(sl)
} else if(length(sl)>1){
  
  slLst <- list()

  for(i in 1:length(sl)){
    slLst[[i]] <- readRDS(sl[[i]])
  }
  
  for(i in 1:length(slLst[[1]])){
    z <- lapply(slLst, '[[', i)
    simlevel[[i]] <- do.call(abind, list(z, along=1))
  }
  
  names(simlevel)<-names(slLst[[1]])

  tot_reps<-dim(simlevel[[1]])[1]
  
  for(i in 1:(length(simlevel)-1)){
    dimnames(simlevel[[i]])[[1]]<-paste0('rep', 1:tot_reps)
  } 
  
}  


  # Fix YEAR.
  simlevel[['YEAR']] <- simlevel[['YEAR']][1:(length(simlevel[['YEAR']])/length(simlevel))]

  plotRP<-FALSE
  plotDrivers<-FALSE
  plotTrajInd<-TRUE
  plotTrajBox<-TRUE
  get_SimLevelplots(x=simlevel, dirIn=here(ResultDirectory, "sim"), dirOut=dirOut, 
                    boxnames=SIMboxplot_these, rpnames=SIMrp_these, trajnames=SIMtraj_these,breakyears=plotBrkYrs)



# Output the memory usage
get_memUsage(runClass = runClass)
cat('\n ---- runPost completed ----\n')

