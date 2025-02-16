

get_replacement <- function(parpop, parmgt, plot=FALSE){
  
  ###### ----- must change L5SAMP here..... --------#######
  # Change setup here it is ridiculous.
  Rfun <- Rfun_BmsySim[[parmgt$RFUN_NM]]
  if(parmgt$RFUN_NM == 'L5SAMP'){
    parpop$B <- tail(parpop$SSBhat, 5)
    parpop$R <- tail(parpop$R, 5)
  }

  # model to approximately bisect the S/R data (goes through origin)
  bimod <- lm(parpop$R ~ 0 + parpop$SSBhat)

  # slp of the bisecting line
  # slp <- coef(bimod)
  slp <- median(parpop$R / parpop$SSBhat)
  
  if(plot){
    xl <- c(0, max(parpop$SSBhat))
    yl <- c(0, max(parpop$R))
    plot(parpop$R ~ parpop$SSBhat, xlim=xl, ylim=yl, main=slp)
    abline(a=0, b=slp)
  }
  
  return(unname(slp))
  
}
  
  

