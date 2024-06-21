

#### Set up environment ####

# empty the environment
# rm(list=ls())

here::i_am("processes/runSim.R")
source('processes/runSetup.R')

source('processes/readin_previous_omval.R')

# if on local machine (i.e., not hpcc) must compile the tmb code
# (HPCC runs have a separate call to compile this code). Keep out of
# runSetup.R because it is really a separate process on the HPCC.
if(runClass == 'local' ){
  source('processes/runPre.R', local=ifelse(exists('plotFlag'), TRUE, FALSE))
}

source(here("processes","EconStorage.R")) 
save_econ_raw<-FALSE
####################These are temporary changes for testing ####################

####################End Temporary changes for testing ####################


#set the rng state based on system time.  Store the random state.
# if we use a plain old date (seconds since Jan 1, 1970), the number is actually too large, but we can just rebase to seconds since Jan 1, 2018.

start<-as.integer(difftime(Sys.time(), as.POSIXct("2018-01-01 00:00:00", "%Y-%m-%d %H:%M:%S"), units="secs")) 
set.seed(start)

oldseed_ALL <- .Random.seed
showProgBar<-TRUE
####################End Parameter and storage Setup ####################
  #This depends on mproc, fyear, and nyear. So it should be run *after* it is reset. I could be put in the runSetup.R script. But since I'm  adjusting fyear and nyear temporarily, I need it here (for now).


top_loop_start<-Sys.time()
top_loop_start
rng_counter<-1
yearitercounter<-0
max_yiter<-nrep*nrow(mproc)*(nyear-fyear+1)

oldseed_mproc <- .Random.seed

#### Top MP loop ####
for(m in 1:nrow(mproc)){
  #Restore the rng state to the value of oldseed_mproc.  For the same values of r, all the management procedures to start from the same RNG state.

  .Random.seed<-oldseed_mproc
  
  print(paste0("model # ",m))
  
  #### Top rep Loop ####
  for(r in 1:nrep){
    print(paste0("rep # ",r, " and model #", m))
    yearitercounter<-0
    iterpb <- txtProgressBar(min = 1, max = max_yiter, style = 3)
    
    manage_counter<-0
    begin_rng_holder[[rng_counter]]<-c(r,m,fyear-1,yrs[fyear-1],.Random.seed)
    rng_counter<-rng_counter+1
        #the econtype dataframe will pass a few things through to the econ model that govern how fishing is turned on/off when catch limits are reached, which sets of coefficients to use, and which prices to use
        if(mproc$ImplementationClass[m]=="Economic"){
         source('processes/setup_Year_Indexing.R')
         source('processes/setupEconType.R')
        }
    
    
    #Store the ie_F and ie_bias terms
    for (i in 1:nstock){
        stock[[i]] <- ie_param_save(stock=stock[[i]])
      }
    
    if(mproc$ImplementationClass[m]=="StandardFisheries" & mproc$ie_override[m]=="TRUE"){
      for (i in 1:nstock){
        if(mproc$ie_source[m]=="Internal"){  
          stock[[i]] <- ie_internal_param_override(stock=stock[[i]], replicate=r, from_model=mproc$ie_from_model[m])
        }
        if(mproc$ie_source[m]!="Internal"){  
          stock[[i]]<-ie_static_param_override(stock=stock[[i]],replicate=r, from_model=mproc$ie_from_model[m], stocknum=i)
        }      
      }
    }
   #### get historic assessment info if there is any
   for (i in 1:nstock){
     #assess_vals <- get_HistAssess(stock = stock[[i]])
      
     stock[[i]] <- get_HistAssess(stock = stock[[i]])
       
     }      

    # Initialize stocks and determine burn-in F
    for(i in 1:nstock){
      stock[[i]] <- get_popInit(stock=stock[[i]])
    
    }

       
    #### Top year loop ####
    for(y in fyear:nyear){
      begin_rng_holder[[rng_counter]]<-c(r,m,y,yrs[y],.Random.seed)
      
      for(i in 1:nstock){
       
        
        stock[[i]] <- get_J1Updates(stock = stock[[i]])
        stock[[i]] <- get_EconSurvey(stock = stock[[i]])
  
      }
      if(mproc$ImplementationClass[m]=="Economic"){ #Run the economic model
        source('processes/withinYearAdmin.R')
      }
      # if burn-in period is over and fishery management has started
      if(y >= fmyearIdx){

        manage_counter<-manage_counter+1 #this only gets incremented when y>=fmyearIdx
        print(paste0("Year ",yrs[y], " of years ", yrs[nyear]))
        for(i in 1:nstock){
          print(paste0("Year ",yrs[y], "working on catch advice for stock ", stock[[i]]$stockName))
          stock[[i]] <- get_advice(stock = stock[[i]])
          #stock[[i]] <- get_relError(stock = stock[[i]])
        }
        
          #Construct the year-replicate index and use those to look up their values from random_sim_draw. This is currently unused.
        if(mproc$ImplementationClass[m]=="Economic"){ #Run the economic model
          # Setup the Jan 1 survey.
          
          # Load economic data from disk, wrangle endogenous bio data to a format ready for econ model 
          source('processes/loadEcon2.R')

          bio_params_for_econ <- get_bio_for_econ(stock,econ_baseline_averages)
          # Print the status of the model.
          cat("Working on Econ module. Replicate", r, "of", nrep, ". This is model", m, "of", nrow(mproc), ". This is year", yrs[y],"of", yrs[nyear], ".\n ")
          source('processes/runEcon_module.R')

          
        }else if(mproc$ImplementationClass[m] == "StandardFisheries"){ #Run the Standard Fisheries model
          for(i in 1:nstock){
            stock[[i]] <- get_implementationF(type = 'adviceWithCatchDeviations',
                                              stock = stock[[i]])
          } # End implementation error in standard fisheries
        }else{
          #Add a warning about invalid ImplementationClass
        }

      } # End of the if "burn-in period is over and fishery management has started" clause 

      for(i in 1:nstock){
        stock[[i]] <- get_mortality(stock = stock[[i]])
        stock[[i]] <- get_indexData(stock = stock[[i]])
      } #End killing fish loop

      # Store results
      for(i in 1:nstock){
        if (y == nyear){
          stock[[i]] <- get_TermrelError(stock = stock[[i]])
        }

        if(y>=fmyearIdx){
          stock[[i]] <- get_fillRepArrays(stock = stock[[i]])
        }
      
      } 
    
      end_rng_holder[[rng_counter]]<-c(r,m,y,yrs[y],.Random.seed)
      rng_counter<-rng_counter+1
      
      # Compute Fleet level HHI and shannon index. Store fishery-year level results
      source('processes/OutputStorage.R')
      
      
      if(showProgBar==TRUE){
          setTxtProgressBar(iterpb, yearitercounter)
        }
    } #End of year loop
  
    # Estimate the implementation error parameters
    for(i in 1:nstock){
      if(mproc$ImplementationClass[m]=="Economic"){
      stock[[i]] <- get_error_params(stock[[i]],fit_ie='lognorm',firstyear=fmyearIdx, lastyear=nyear)
    }

      # also store the ie_F and ie_bias
      stock[[i]]$omval$ie_F[r,m] <-  stock[[i]]$ie_F 
      stock[[i]]$omval$ie_bias[r,m] <-  stock[[i]]$ie_bias
    }
    
    # ReStore the ie_F and ie_bias terms
    for (i in 1:nstock){
        stock[[i]]<-ie_param_reset(stock=stock[[i]])
    }

    #Reset econ_baselines
    econ_baseline_averages<-econ_baseline_averages_backup  
    
    print(paste0("Model", m, " of rep # ",r, "done."))
    ####################################  
    #Save as we go along.
    # Make up a stub for model 1 and replicate 1. Check to make sure this is does not exist.
    if (r==1 & m==1){
    td2 <- as.character(Sys.time())
    td2 <- gsub(':', '', td2)
    td2 <- paste(gsub(' ', '_', td2), round(runif(1, 0, 10000)), sep='_')
    
      if(file.exists(paste0(ResultDirectory,'/sim/omvalGlobal', td2, '.Rdata'))==TRUE){
       stop("The omvalGlobal for model1 and rep1 already exists. This is a problem") 
      }
    
      if(file.exists(paste0(ResultDirectory,'/sim/simlevelresults', td2, '.Rds'))==TRUE){
        stop("The simlevel file for model1 and rep1 already exists. This is a problem") 
      }
    }
    #### save results ####
    cat("Saving Replicate ",r, "from model ",m ,". The time is ", as.character(Sys.time()))
    
    
    omvalGlobal <- sapply(1:nstock, function(x) stock[[x]]['omval'])
    names(omvalGlobal) <- sapply(1:nstock, function(x) stock[[x]][['stockName']])
    save(omvalGlobal, file=paste0(ResultDirectory,'/sim/omvalGlobal', td2, '.Rdata'), compress=FALSE)
    saveRDS(simlevelresults, file=paste0(ResultDirectory,'/sim/simlevelresults', td2, '.Rds'), compress=FALSE)
    ####################################  
    
    
    
  } #End of mproc loop
} #End rep loop

top_loop_end<-Sys.time()
big_loop<-top_loop_end-top_loop_start
big_loop
#econ_timer
      # Output run time / date information and OM inputs. The random number is
  # just ensuring that no simulations will be overwritten because the hpcc
  # might finish some in the same second. td is used for uniquely naming the
  # output file as well as for listing in the output results.

  td <- as.character(Sys.time())
  td2 <- gsub(':', '', td)
  td2 <- paste(gsub(' ', '_', td2), round(runif(1, 0, 10000)), sep='_')

  begin_rng_holder<-do.call(rbind,begin_rng_holder)
  begin_rng_holder<-as.data.frame(begin_rng_holder)
  colnames(begin_rng_holder)[1:4]<-c("rep","model","y", "year")
  rownames(begin_rng_holder)<-NULL
  
  end_rng_holder<-do.call(rbind,end_rng_holder)
  end_rng_holder<-as.data.frame(end_rng_holder)
  colnames(end_rng_holder)[1:4]<-c("rep","model","y", "year")
  rownames(end_rng_holder)<-NULL
  
  if (save_econ_raw==TRUE){
    saveRDS(begin_rng_holder, file.path(econ_results_location,  paste0("begin_rng_",td2, ".Rds")), compress=FALSE)
    saveRDS(end_rng_holder, file.path(econ_results_location,  paste0("end_rng_",td2, ".Rds")), compress=FALSE)
}

  for(i in 1:nstock){
    pth <- paste0(ResultDirectory,'/fig/', sapply(stock, '[[', 'stockName')[i])
    dir.create(pth, showWarnings = FALSE)
  }


  
  if(runClass == "Local"){
    write.csv(mproc, file=file.path(ResultDirectory,"fig",mprocfile), row.names=FALSE)
    # Copy set_om_parameters_global.R into the results folder
    file.copy('modelParameters/set_om_parameters_global.R', file.path(ResultDirectory,"set_om_parameters_global.R"))
    
    omparGlobal <- readLines('modelParameters/set_om_parameters_global.R')
    cat('\n\nSuccess.\n\n',
        'Completion at: ',
        td,
        file=paste0(ResultDirectory,'/runInfo.txt'))
    cat('\n\n\n\n\n\n\n\n  ##### Global OM Parameters ##### \n\n',
        omparGlobal,
        file=paste0(ResultDirectory,'/runInfo.txt'), sep='\n', append=TRUE)
    for(i in 1:nstock){
      cat('\n\n\n\n\n\n\n\n  ##### Stock OM Parameters ##### \n\n',
          readLines(fileList[i]),
          file=paste0(ResultDirectory,'/runInfo.txt'), sep='\n', append=TRUE)
    }
  }



   if(runClass =="Local"){
     # Note that runPost.R re-sets the containers; results have already been
     # saved however.
     source('processes/runPost.R')
   }


  print(unique(warnings()))
  cat("You ran",r, "Replicates. You ran",m,"models. You ran from year", yrs[fmyearIdx], " to year", yrs[y],".\n ")
  top_loop_end-top_loop_start
  cat('\n ---- Successfully Completed ----\n')
  Sys.time()

