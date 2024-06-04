# A function to zero out trips that are closed after estimating an ASCLOGIT.
#
# tds: working targeting dataset with asclogit coefficients 
# open_hold: a dataset of hullnum and spstock2 with one extra column (open=1 if open and =0 if closed).
# I need to fix this, because it does not close an entire stock area when a single catch limit is reached. 
#  


zero_out_closed_asc_cutout <- function(tds,open_hold){
  num_closed<-sum(open_hold$underACL==FALSE)
  if (num_closed==0){
    # If nothing is closed, just return tds
  } else{
    
  #tdsQ<-left_join(tds,open_hold, by=c("spstock2"="spstock2"))
  #A data table left join
  tds<-open_hold[tds, on="spstock2"]
  
  
  tds$underACL[which(tds$spstock2=="nofish")]<-TRUE
  tds$prhat[tds$underACL==FALSE]<-0

  tds[, prsum := sum(prhat), by = id]
  tds[, prhat:=prhat/prsum]
  
  #tds$prhat<- tds$prhat/tds$prsum
  
  }
  return(tds)
}

