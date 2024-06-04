# A function to adjust the catch and/or landings multipliers for targeted and non_targeted Allocated Multispecies stocks.
##########################
# What am I going to do for unallocated multispeices stocks and non-multispecies stocks?
##########################
# wt: the working_targeting dataset
# fh: fishery_holder, we will pull in a few things
  #stockarea_open, under_ACL, mults_allocated
# ec_type: econtype taken from the mproc dataframe

##############################################################################
# Multi: For the "Multi" econ model, set the landings multipliers=0 for all spstock2 that have stockarea_open==FALSE
# Multi models use stockarea_open as the condition 
# Single models use the underACL columns as the conditon.

#CatchZero=TRUE indictes that the catch multipliers should be set to zero; 
#CatchZero=FALSE indictes that the catch multipliers should be taken from the data; 

#LandZero=TRUE indictes that the landings multipliers should be set to zero; 
#LandZero=FALSE indictes that the landings multipliers should be taken from the data; 

# CatchZero=TRUE implies LandZero=TRUE 

joint_adjust_allocated_mults <- function(wt,fh, ec_type){
    mul_alloc<-fh[mults_allocated==1]
    closeds<-NULL
    
    #For Multi-type models, look at the stockare_open column. For single type models, look at the underacl column
    
    if (ec_type$EconType=="Multi"){
      closeds<-mul_alloc[stockarea_open==FALSE]$spstock2
    }else if (ec_type$EconType=="Single"){
      closeds<-mul_alloc[underACL==FALSE]$spstock2
    }
    
    #For CatchZero=FALSE and LandZero=TRUE, set the landings multipliers to zero
    #For CatchZero=TRUE and LandZero=TRUE, set the catch and landings multipliers to zero
    #For CatchZero=FALSE and LandZero=FALSE, leave the multipliers alone. 
    
    
    if(ec_type$CatchZero=="FALSE"  & ec_type$LandZero=="TRUE"){
      closed<-paste0("l_", closeds)
    } else if  (ec_type$CatchZero=="TRUE" & ec_type$LandZero=="TRUE"){
      closed<-c(paste0("l_", closeds), paste0("c_",closeds))
    } else if  (ec_type$CatchZero=="FALSE" & ec_type$LandZero=="FALSE"){
      #This has not been tested in combination with the wt[,(closed):=0] line
      #closed<-NULL
    } else if  (ec_type$CatchZero=="TRUE" & ec_type$LandZero=="FALSE"){
      stop("Imposssible combination of Catch and Landings Multipliers. Check input parameters mproc.")
    }
    
    if (length(closeds)==0){
      #do nothing
    } else {
    # Set c_ and/or l_ mults to zero. 
      
        wt[, (closed):=0]
    # do not set harvest_sim=0 by just doing 
      # wt[, (harvest_sim):=0]
    # wt[spstock2 %in% closeds, harvest_sim :=0]
    }
    

    
    return(wt)
}

