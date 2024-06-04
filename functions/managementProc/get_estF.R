#Function to get what estimated F based on catch. 
#Used to make sure estimated F is not over the estimated OFL. 
get_estF<-function(catchproj,parmgtproj,parpopproj,parenv,Rfun,stockEnv){
    nage <- length(parpopproj$sel)
    N <- matrix(0, nrow=1, ncol=nage)
    init <- tail(parpopproj$J1N, 1)
    
    #Rho-adjustments to SSB if this option is turned on 
    if (mproc$rhoadjust[m]==TRUE & y>fmyearIdx & stockEnv$Mohns_Rho_SSB[y]>0.15){
      init<-init/(1+stockEnv$Mohns_Rho_SSB[y])
    }
    N[1,] <- init 
    for(a in 2:(nage-1)){
        
      #init= population at the beginning of the year in t-1  
      #exponential survival to the next year/age (t)
      N[1,a] <- init[a-1] * exp(-parpopproj$sel[a-1]*parpopproj$Fhat - 
                                  parpopproj$M[a-1])
    }
    
    #Deal with the plus group
    N[1,nage] <- init[nage-1] * exp(-parpopproj$sel[nage-1] * parpopproj$Fhat - 
                                      parpopproj$M[nage-1]) + 
      init[nage] * exp(-parpopproj$sel[nage] * parpopproj$Fhat - 
                         parpopproj$M[nage])
    
    #Recruitment 
    R<-parpopproj$R
    
    N[1,1] <- prod(tail(R,5))^(1/5)

    Fest <- get_F(x = catchproj,
                    Nv = N, 
                    slxCv = parpopproj$sel, 
                    M = parpopproj$M, 
                    waav = parpopproj$waa)

  return(Fest)
}
