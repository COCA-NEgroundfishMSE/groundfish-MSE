# A function to zero out trips that are closed after estimating an ASCLOGIT.
# If this is a "Multi" model, then entire stockareas close.
# If "stockarea_open=FALSE" for a stock, then the probability of targeting that stock is set to zero. That probability is redistributed proportionally.

# If this is a "Single" model, then only a stock with  close.
# If "underACL=FALSE" for a stock, then the probability of targeting that stock is set to zero. That probability is redistributed proportionally.



# tds: working targeting dataframe joined to  asclogit coefficients 
# open_hold:a data frame contains stock attributes: "stocklist_index","stockName","spstock2","sectorACL","nonsector_catch_mt","bio_model","SSB", "mults_allocated", "stockarea","non_mult","ln_trawlsurvey", "ln_obs_trawlsurvey",underACL,stockarea_open,cumul_catch_pounds,targeted)  
# ec_type: econtype taken from the mproc dataframe
#  


zero_out_closed_areas_asc_cutout <- function(tds,open_hold,ec_type){
  # Merge, drop out the targeted colunm, ensure that nofish is a possibility.
  tds<-open_hold[tds, on="spstock2"]
  tds[, targeted := NULL]
  tds[spstock2=="nofish", underACL :=TRUE]
  tds[spstock2=="nofish", stockarea_open :=TRUE]
  
  # If any stockareas are closed, set the probability of fishing for stocks in that area to zero.
  if (ec_type$EconType=="Multi"){
  num_closed<-sum(open_hold$stockarea_open==FALSE)
    if (num_closed==0){
      # If nothing is closed, just return tds
    } else{
      tds[stockarea_open==FALSE, prhat :=0]
      tds[, prsum := sum(prhat), by = id]
      tds[, prhat:=prhat/prsum]
      }
  }
  
  # If any stocks are closed, set the probability of fishing for those stocks to zero.
  if (ec_type$EconType=="Single"){
    num_closed<-sum(open_hold$underACL==FALSE)
    if (num_closed==0){
      # If nothing is closed, just return tds
    } else{
      tds[underACL==FALSE, prhat :=0]
      tds[, prsum := sum(prhat), by = id]
      tds[, prhat:=prhat/prsum]
      }	    
  }
  

 
  return(tds)
  
}

