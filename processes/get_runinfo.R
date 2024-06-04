


# Determine what platform the code is running on (Duplicated purposefully
# in runPre.R for running on HPCC)
platform <- Sys.info()['sysname']
servername <- Sys.info()['nodename']
# Determine whether or not this is a run on the HPCC by checking the name of
# the node
if(platform == 'Linux'){
  # Dig into the environmental variables
  evndir <- system('printenv LSF_ENVDIR', intern=TRUE)
  
  # Test if environmental variable exists. If this particular one does not then
  # then you are on a local system ... must include length()>0 to avoid an
  # error.
  if(length(evndir) > 0 && evndir == '/lsf/conf'){
    runClass <- 'HPCC'
  }else if(servername=='neptune'){
    runClass<-'neptune'
  }else if(servername=='mlee-linux-pc'){
    runClass<-'mleeLocal'
  }else if(Sys.info()['effective_user']=='mlee'){
    runClass<-'mleeContainer'
  }
}else{
  runClass <- 'Local'
}

