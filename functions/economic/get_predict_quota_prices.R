

# A function to predict quota prices, using the exponential model of quota prices 
# No arguments, which is kind of lame.
# returns a data.table with many columns and 1 row: 
   # columns are q_spstock2 for the allocated species
get_predict_quota_prices <- function(){
  # Construct RHS variables for the selection and quota price equations 
  # Extract elements of fishery_holder that you need to compute fish prices
  quarterly<-fishery_holder[,c("stocklist_index","stockName","spstock2","sectorACL","cumul_catch_pounds", "mults_allocated")]
  quarterly<-quarterly[which(mults_allocated==1),]
  quarterly$quota_remaining_BOQ<-quarterly$sectorACL-(quarterly$cumul_catch_pounds/(pounds_per_kg*kg_per_mt))

  #replace negative quota remaining with zero for purposes of quota prices computation
  quarterly$quota_remaining_BOQ[quarterly$quota_remaining_BOQ<=0]<-0
  quarterly$fraction_remaining_BOQ<-quarterly$quota_remaining_BOQ/quarterly$sectorACL
  
  #Scale to 1000s of mt
  quarterly$quota_remaining_BOQ<-quarterly$quota_remaining_BOQ/1000
  
  
  #Quarterly dummmies
  quarterly$q_fy<-q_fy
  quarterly$q_fy_1<-as.integer(q_fy==1)
  quarterly$q_fy_2<-as.integer(q_fy==2)
  quarterly$q_fy_3<-as.integer(q_fy==3)
  quarterly$q_fy_4<-as.integer(q_fy==4)
  
  #Fill in extra data 
  quarterly$constant<-1
  
  # Pull in quarterly prices
  # merge quarterly prices on spstock2 and q_fy into the quarterly dataframe
  quarterly <- merge(quarterly,quarterly_prices, by=c("spstock2","q_fy"), all.x = FALSE, all.y = FALSE)
  
  #Names of RHS vars in the selection equation
  selectRHS_names<-c("quota_remaining_BOQ","fraction_remaining_BOQ","q_fy_2","q_fy_3","q_fy_4","constant")
  selectcoefs<-paste0("selection:", selectRHS_names)

  # subset the RHS vars and coefficients. Transpose the coefficients
  selectRHS<-quarterly[,..selectRHS_names]
  A<-t(as.matrix(quotaprice_coefs[,..selectcoefs]))
  
  # Compute the probability that the quota price will be positive
  Z<-as.matrix(selectRHS)
  
  ZA<-Z%*%A
  psel<-pnorm(ZA)
  colnames(psel)<-c("psel")
  
  # Compute the YTRUN and YCEN
  
  # Grab sigma, the names of the coefficients, names of the data  and put them into matrices
  sig<-quotaprice_coefs$sigma[1]
  
  levelRHS_names<-c("live_priceGDP","quota_remaining_BOQ","proportion_observed", "q_fy_2","q_fy_3","q_fy_4","constant")
  levels_coefs<-paste0("lnbadj_GDP:", levelRHS_names)
  
  levelsRHS<-quarterly[,..levelRHS_names]
  B<-t(as.matrix(quotaprice_coefs[,..levels_coefs]))
  X<-as.matrix(levelsRHS)
  
  #Compute XB of the levels equation
  XB<-X%*%B
  # YTRUN
  # 		local ytrun exp(xb(lnwage) +`sig'^2/2)
  ytrun<-exp(XB+sig^2/2)
  colnames(ytrun)<-c("ytrun")
  
  quarterly<-cbind(quarterly,psel,ytrun)

  #Compute normalize ytrun.  
  quarterly[,ytrun:= ytrun*fGDPtoSFD]
  
  #Construct ycen   
  # In stata: psel*ytrun
  quarterly[,ycen:= psel*ytrun]
  # Put an upper bound on quota prices
  quarterly[,ub_qp :=max(3*live_priceGDP,10)]
  quarterly[ycen >= ub_qp, ycen := ub_qp]
  
  # If there is less than 10% quota remaining, set the quota price the largest of the predicted price or the output price  
  quarterly[fraction_remaining_BOQ <= .10, ycen := max(ycen, live_priceGDP)]
  
  # If there is less than 2% quota remaining, set the quota price to the max defined above.
  quarterly[fraction_remaining_BOQ <= .02, ycen := ub_qp]
  
  # And a lower bound of 1 cent
  quarterly[ycen <= 0.01, ycen := 0.01]
  
  
  keepcols<-c("spstock2","ycen")  
  quarterly<-quarterly[,..keepcols]
  quarterly$spstock2<-paste0("q_",quarterly$spstock2)
  # reshape
  quarterly$m<-1
  quarterly<-dcast(quarterly,  m~ spstock2, value.var="ycen")
  quarterly$m<-NULL
  return(quarterly)
}

