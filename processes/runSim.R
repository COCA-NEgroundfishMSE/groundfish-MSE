

#### Set up environment ####

# empty the environment
rm(list=ls())
source('processes/runSetup.R')

# if on local machine (i.e., not hpcc) must compile the tmb code
# (HPCC runs have a separate call to compile this code). Keep out of
# runSetup.R because it is really a separate process on the HPCC.
if(runClass != 'HPCC'){
  source('processes/runPre.R', local=ifelse(exists('plotFlag'), TRUE, FALSE))
}

####################These are temporary changes for testing ####################
# econ_timer<-0

#  mproc_bak<-mproc
#
# mproc<-mproc_bak[5:5,]
# nrep<-1
# nyear<-200
## For each mproc, I need to randomly pull in some simulation data (not quite right. I think I need something that is nrep*nyear long.  Across simulations, each replicate-year gets the same "econ data"
####################End Temporary changes for testing ####################


#set the rng state based on system time.  Store the random state.
# if we use a plain old date (seconds since Jan 1, 1970), the number is actually too large, but we can just rebase to seconds since Jan 1, 2018.

start<-Sys.time()-as.POSIXct("2018-01-01 00:00:00", "%Y-%m-%d %H:%M:%S")
start<-as.double(start)*100
set.seed(start)

oldseed_ALL <- .Random.seed
showProgBar<-TRUE
####################End Parameter and storage Setup ####################
  #This depends on mproc, fyear, and nyear. So it should be run *after* it is reset. I could be put in the runSetup.R script. But since I'm  adjusting fyear and nyear temporarily, I need it here (for now).


source('processes/setupYearIndexing.R')
top_loop_start<-Sys.time()

#### Top rep Loop ####
for(r in 1:nrep){
    oldseed_mproc <- .Random.seed
  print(paste0("rep # ",r))
  
  #### Top MP loop ####
  for(m in 1:nrow(mproc)){

       manage_counter<-0

       #Restore the rng state to the value of oldseed_mproc.  For the same values of r, all the management procedures to start from the same RNG state.
       .Random.seed<-oldseed_mproc

        #the econtype dataframe will pass a few things through to the econ model that govern how fishing is turned on/off when catch limits are reached, which sets of coefficients to use, and which prices to use
        if(mproc$ImplementationClass[m]=="Economic"){
          
         source('processes/setupEconType.R')
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
      for(i in 1:nstock){
        stock[[i]] <- get_J1Updates(stock = stock[[i]])
      }
      
      source('processes/withinYearAdmin.R')
      begin_rng_holder[[yearitercounter]]<-c(r,m,y,yrs[y],.Random.seed)

      # if burn-in period is over...
      if(y >= fmyearIdx){

        manage_counter<-manage_counter+1 #this only gets incremented when y>=fmyearIdx

        for(i in 1:nstock){
          stock[[i]] <- get_advice(stock = stock[[i]])
          #stock[[i]] <- get_relError(stock = stock[[i]])
        }
        
          #Construct the year-replicate index and use those to look up their values from random_sim_draw. This is currently unused.

        if(mproc$ImplementationClass[m]=="Economic"){ #Run the economic model

          for(i in 1:nstock){
            # Specific "survey" meant to track the population on Jan1
            # for use in the economic submodel. timeI=0 implies Jan1.
            stock[[i]]<- within(stock[[i]], {
              IJ1[y,] <- get_survey(F_full=0, M=0, N=J1N[y,], slxC[y,],
                                slxI=selI, timeI=0, qI=qI)
            })
          } # End survey loop


          # ---- Run the economic model here ----
          source('processes/loadEcon2.R')


          bio_params_for_econ <- get_bio_for_econ(stock,econ_baseline)

          source('processes/runEcon_module.R')

        }else if(mproc$ImplementationClass[m] == "StandardFisheries"){
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
    
      end_rng_holder[[yearitercounter]]<-c(r,m,y,yrs[y],.Random.seed)

          #Save economic results once in a while to a csv file.
        if(mproc$ImplementationClass[m]=="Economic" &(y >= fmyearIdx) & (chunk_flag==0 | yearitercounter==max_yiter)) {
            revenue_holder<-rbindlist(revenue_holder)
            tda <- as.character(Sys.time())
            tda <- gsub(':', '', tda)
            tda<-gsub(' ', '_', tda)
            tda2 <- paste0(tda,"_", round(runif(1, 0, 10000)))
            write.table(revenue_holder, file.path(econ_results_location, paste0("econ_",tda2, ".csv")), sep=",", row.names=FALSE)
            revenue_holder<-list()
        } #End save economic results if statement

        if(showProgBar==TRUE){
          setTxtProgressBar(iterpb, yearitercounter)
        }
    } #End of year loop 
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


    saveRDS(begin_rng_holder, file.path(econ_results_location,  paste0("begin_rng_",td2, ".Rds")), compress=FALSE)
    saveRDS(end_rng_holder, file.path(econ_results_location,  paste0("end_rng_",td2, ".Rds")), compress=FALSE)


  for(i in 1:nstock){
    pth <- paste0(ResultDirectory,'/fig/', sapply(stock, '[[', 'stockName')[i])
    dir.create(pth, showWarnings = FALSE)
  }

  #### save results ####
  omvalGlobal <- sapply(1:nstock, function(x) stock[[x]]['omval'])
  names(omvalGlobal) <- sapply(1:nstock, function(x) stock[[x]][['stockName']])
  save(omvalGlobal, file=paste0(ResultDirectory,'/sim/omvalGlobal', td2, '.Rdata'))

  if(runClass != 'HPCC'){
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



  if(runClass != 'HPCC'){
    # Note that runPost.R re-sets the containers; results have already been
    # saved however.
    source('processes/runPost.R')
  }


  print(unique(warnings()))

  cat('\n ---- Successfully Completed ----\n')
