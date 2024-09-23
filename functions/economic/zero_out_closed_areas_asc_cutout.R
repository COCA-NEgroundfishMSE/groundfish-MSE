# A function to zero out trips that are closed after estimating an ASCLOGIT.
# If this is a "Multi" model, then entire stockareas close.
# If "stockarea_open=FALSE" for a stock, then the probability of targeting that stock is set to zero. That probability is redistributed proportionally.

# If this is a "Single" model, then only a stock with  close.
# If "underACL=FALSE" for a stock, then the probability of targeting that stock is set to zero. That probability is redistributed proportionally.



# tds: working targeting dataset with asclogit coefficients 
# open_hold: a dataset of hullnum and spstock2 with one extra column (open=1 if open and =0 if closed).
# ec_type: econtype taken from the mproc dataframe
#  


zero_out_closed_areas_asc_cutout <- function(tds,open_hold,ec_type){
  
  if (ec_type$EconType=="Multi"){
  num_closed<-sum(open_hold$stockarea_open==FALSE)
    if (num_closed==0){
      # If nothing is closed, just return tds
    } else{
      tds<-open_hold[tds, on="spstock2"]
      tds[spstock2=="nofish", stockarea_open :=TRUE]
      tds[stockarea_open==FALSE, prhat :=0]
    }
  }
  
  if (ec_type$EconType=="Single"){
    num_closed<-sum(open_hold$underACL==FALSE)
    if (num_closed==0){
      # If nothing is closed, just return tds
    } else{
      
      tds<-open_hold[tds, on="spstock2"]
      tds[underACL==FALSE, prhat :=0]
    }	    
  }
  

  tds[, targeted := NULL]
  tds[spstock2=="nofish", stockarea_open :=TRUE]
  tds[, prsum := sum(prhat), by = id]
  tds[, prhat:=prhat/prsum]
 
  return(tds)
  
}

