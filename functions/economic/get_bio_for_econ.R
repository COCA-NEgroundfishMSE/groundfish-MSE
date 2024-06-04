# Collect biological parameters for the economic model into a dataframe. 
# Do a little processing to construct ACLs for the sector fleet
# This function runs 1x per simulation year, so it's not worth spending time optimizing.
# There are *many* biological parameters stored in the stock lists
# This collects a few of them into lists that are easier to pass to the economic model

# trawlsurvey extraction not working, might be a timing thing. 
# myfields<-c("stocklist_index","stockName","spstock2", ACL", "SSB", "IN","waa")

get_bio_for_econ=function(stock,basecase){
  sn<-lapply(X = stock, FUN = `[[`, "stockName")
  
  #This stacks all the the metrics into individual lists
  ACL<-lapply(X = stock, FUN = `[[`, "ACL") 
  ACL<-lapply(X = ACL, FUN = `[`, y)
  
  SSB<-lapply(X = stock, FUN = `[[`, "SSB")
  SSB<-lapply(X = SSB, FUN = `[`, y)
  
  trawlsurvey<-lapply(X = stock, FUN = `[[`, "sumEconIW")
  trawlsurvey<-lapply(X = trawlsurvey, FUN = `[`, y)
  
  obs_trawlsurvey<-lapply(X = stock, FUN = `[[`, "obs_sumEconIW")
  obs_trawlsurvey<-lapply(X = obs_trawlsurvey, FUN = `[`, y)
  
  
  # Hack the ACL to 1e6 mt if it is null
  ACL<-replace(ACL, sapply(ACL, is.null), 1e6) 
  
  #Stack these into a dataframe and give the columns good names
  biocontain<-do.call(rbind,lapply(sn,data.frame))
  biocontain<-cbind(c(1:nrow(biocontain)),biocontain)
  biocontain<-cbind(biocontain,do.call(rbind,lapply(trawlsurvey,data.frame)))
  biocontain<-cbind(biocontain,do.call(rbind,lapply(obs_trawlsurvey,data.frame)))
  biocontain<-cbind(biocontain,do.call(rbind,lapply(SSB,data.frame)))
  biocontain<-cbind(biocontain,do.call(rbind,lapply(ACL,data.frame)))
  biocontain<-cbind(biocontain,1)
  colnames(biocontain)<-c("stocklist_index","stockName","trawlsurvey","obs_trawlsurvey","SSB","ACL","bio_model")
  biocontain$stockName<- as.character(biocontain$stockName)
  
  #convert trawlsurvery and obs_trawlsurvey from mt to kg and take logs
  biocontain$trawlsurvey<-log(biocontain$trawlsurvey)
  biocontain$obs_trawlsurvey<-log(biocontain$obs_trawlsurvey)
  #rename
  colnames(biocontain)[colnames(biocontain) %in% c("trawlsurvey", "obs_trawlsurvey")] <- c("ln_trawlsurvey", "ln_obs_trawlsurvey")
  
  #Parse the stockName column
  biocontain<-separate(biocontain,stockName,into=c("spstock2","variant"), sep="_", remove=FALSE, fill="right")
  biocontain$spstock2<- as.character(biocontain$spstock2)
  
  #Pull in baseline ACLs from historical data, mark rows that have a biological model, and compute the sector and non-sector ACLs
  rownames(biocontain)<- c()
  biocontain<-merge(biocontain,basecase,by="spstock2",all=TRUE)
  biocontain<-within(biocontain, ACL[is.na(ACL)] <- mean_baselineACL_mt[is.na(ACL)])
  
  biocontain<-within(biocontain, bio_model[is.na(bio_model)] <- 0)
             
  biocontain$sectorACL<-biocontain$ACL*biocontain$sector_frac
  biocontain$nonsector_catch_mt<-biocontain$ACL*(1-biocontain$sector_frac)
  biocontain<-as.data.table(biocontain)
  setorder(biocontain,spstock2)
  
  return(biocontain)
}