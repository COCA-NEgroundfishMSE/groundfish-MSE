# A function to handle jointness in production (technical interactions) 
# Within the c_, l_, p_, q_, and r_ columns, the spstock2's need to be in the same order.
# Inputs
#  wt: The working_targeting_dataset that contains coefficients and independent variables. 
# 	
# Outputs: 
# a modified version of the wt data table withextra/overwritten columns
# the c_ columns start as "catch multipliers", but end up as "catch"
# the l_ columns start as "landings multipliers", but end up as "landings"
# The p_columns start as "lag prices", and end up as "lag revenue ==expected revenue, by stock"
# The q_columns start as "quota prices", and end up as "quota costs, by stock"
# the r_columns start as "prices", and end up as "actual revenue, by stock"
# exp_rev_total is updated as sum lag_price*landings minus sum quota_price*catch
# actual_rev_total is updated as sum price*landings minus sum quota_price*catch


get_joint_production <- function(wt,spstock_names, fh, ec_type){

  catches<-paste0("c_",spstock_names)
  landings<-paste0("l_",spstock_names)
  daylimits <-paste0("dl_",spstock_names)
  quotaprices<-paste0("q_",spstock_names)
  lagp<-paste0("p_",spstock_names)
  prices<-paste0("r_",spstock_names)
  
  # overwrite the c_ multiplier and the l_multipliers with catch and landings in pounds
  # overwrite the quotaprices with quotacost
  # overwrite the lagp with expected revenue
  # overwrite the prices with actual revenue
  # This code looks really janky. It also looks fragile to reordering the catches, landings, daylimits, quotaprices, lagp, and 
  # prices vectors. But those are all set immediately above and depend on spstock_names. So, the order shoudl be okay.
  for(idx in 1:length(spstock_names)){
    set(wt, i = NULL, j = catches[idx], value = wt[[catches[idx]]]*wt[['harvest_sim']])
    set(wt, i = NULL, j = landings[idx], value = wt[[landings[idx]]]*wt[['harvest_sim']])
    
    #set(wt, i = NULL, j = landings[idx], value = ifelse(is.na(wt[[daylimits[idx]]]), wt[[landings[idx]]], ifelse(wt[[landings[idx]]]>= wt[[daylimits[idx]]], wt[[daylimits[idx]]], wt[[landings[idx]]])))
    wt [, landings[idx]:= ifelse(is.na(wt[[daylimits[idx]]]), wt[[landings[idx]]], ifelse(wt[[landings[idx]]] >= wt[[daylimits[idx]]], wt[[daylimits[idx]]], wt[[landings[idx]]]))]
    
    set(wt, i = NULL, j = quotaprices[idx], value = wt[[quotaprices[idx]]]*wt[[catches[idx]]])
    set(wt, i = NULL, j = lagp[idx], value = wt[[lagp[idx]]]*wt[[landings[idx]]])
    set(wt, i = NULL, j = prices[idx], value = wt[[prices[idx]]]*wt[[landings[idx]]])
  }
  
  ##compute quota costs, actual revenue, and expected revenue   
  
  # Add up the quota_cost, expected rev, and actual rev columns
  wt[,quota_cost :=rowSums(.SD), .SDcols = quotaprices]
  wt[,exp_rev_total :=rowSums(.SD), .SDcols = lagp]
  wt[,actual_rev_total :=rowSums(.SD), .SDcols = prices]

    # Subtract off the quota costs
  wt[,exp_rev_total :=exp_rev_total - quota_cost]
  wt[,actual_rev_total :=actual_rev_total - quota_cost]
  
    
  mul_alloc<-fh[mults_allocated==1]
 
 #if (ec_type$EconType=="Multi"){
 #    closeds<-mul_alloc[stockarea_open==FALSE]$spstock2
 #  }else if (ec_type$EconType=="Single"){
 #    closeds<-mul_alloc[underACL==FALSE]$spstock2
 #  }
   
  # Stocks that are closed get negative expected revenue
  closeds<-mul_alloc[underACL==FALSE]$spstock2
  
  
  wt[spstock2 %in% closeds, exp_rev_total :=min(-1e6,exp_rev_total)]
  wt[spstock2 %in% closeds, actual_rev_total :=0]
    

  return(wt)
  
}

