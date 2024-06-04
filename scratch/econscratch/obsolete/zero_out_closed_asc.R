# A function to zero out trips that are closed after estimating an ASCLOGIT.
#
# tds: working targeting dataset with asclogit coefficients 
# open_hold: a dataset of hullnum and spstock2 with one extra column (open=1 if open and =0 if closed).
# I need to fix this. 
#  


zero_out_closed_asc <- function(tds,open_hold){

  tds<-left_join(tds,open_hold, by=c("spstock2"="spstock2"))
  tds$open[which(tds$spstock2=="nofish")]<-"TRUE"
  #tds<-merge(tds,open_hold, by=c("spstock2"))
  tds$prhat[tds$open=="FALSE"]<-0
  tds<-as.data.table(tds)
  # 
  tds<-tds[, prsum := sum(prhat), by = id]
  
  tds$prhat<- tds$prhat/tds$prsum

  return(tds)
}

