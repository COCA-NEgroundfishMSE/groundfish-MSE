
# Get the result directory path
source('processes/identifyResultDirectory.R')

# Get the run info so the functions work appropriately whether they are
# on Windows or Linux and whether this is an HPCC run or not.
# source('processes/get_runinfo.R')
source('processes/runSetup.R')


# Load in the stock-level simulation results
fl <- list.files(file.path(ResultDirectory, 'sim'), pattern="omvalGlobal", full.names=TRUE)

# load all the functions
ffiles <- list.files(path='functions/', full.names=TRUE, recursive=TRUE)
invisible(sapply(ffiles, source))

# load the required libraries
source('processes/loadLibs.R')
flLst <- list()
for(i in 1:length(fl)){
  load(fl[i])
  flLst[[i]] <- omvalGlobal
  names(flLst[[i]]) <- names(omvalGlobal)
}

# Load in the aggregate simulation results
sl <- list.files(file.path(ResultDirectory, 'sim'), pattern="simlevelresults", full.names=TRUE)

simlevel <-list()

if(length(sl)>=1){
  for(i in 1:length(sl)){
    simlevel[[i]]<-readRDS(sl[i])
  }
}



boxplot_these<-c("SSB", "SSB_cur", "R", "F_full", "sumCW", "annPercentChange", 
  "meanSizeCN", "meanSizeIN", "OFdStatus", "OFgStatus" ,
  "mxGradCAA", "sumEconIW")
rp_these<-c("FPROXY", "SSBPROXY")

traj_these <- c("SSB", "SSB_cur", "R", "F_full", "sumCW", 
              "ginipaaCN", "ginipaaIN", "OFdStatus",
              "mxGradCAA",
              "relE_qI", "relE_qC", "relE_selCs0", "relE_selCs1",
              "relE_ipop_mean", "relE_ipop_dev",
              "relE_R_dev", "relE_SSB", "relE_N","relE_CW", "relE_IN",
              "relE_R", "relE_F", "OFgStatus",   #AEW
              "FPROXY", "SSBPROXY","sumEconIW")

for(i in 1:length(flLst[[1]])){

  omval <- get_simcat(x=lapply(flLst, '[[', i))
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
            boxnames=boxplot_these, rpnames=rp_these, trajnames=traj_these,breakyears=plotBrkYrs, py0=37)
  

}

# Output the management procedures text file in the figure directory
get_catdf(df = mproc, file = paste0(ResultDirectory,'/fig/',mprocfile))

# Output the memory usage
get_memUsage(runClass = runClass)
