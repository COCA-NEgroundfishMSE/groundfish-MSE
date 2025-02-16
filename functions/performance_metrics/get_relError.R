get_relError <- function(stock){

  out <- within(stock, {

    #### Calculate rel errors ####
    CN[y,] %*% waa[y,]
    if(mproc[m,'ASSESSCLASS'] == 'CAA' & y > fmyearIdx-1){
      relE_SSB[y-1] <- mean(get_relE(SSBhat, get_dwindow(SSB, sty, y-1)))
      relE_CW[y-1] <- mean(get_relE(rep$sumCW, get_dwindow(sumCW, sty, y-1)))
      relE_IN[y-1] <- mean(get_relE(rep$sumIN, get_dwindow(sumIN, sty, y-1)))
      relE_qI[y-1] = get_relE(rep$log_qI, log(qI))
      relE_qC[y-1] = get_relE(rep$log_qC, log(qC))
      relE_selCs0[y-1] = get_relE(rep$log_selC[1], log(selC['s0']))
      relE_selCs1[y-1] = get_relE(rep$log_selC[2], log(selC['s1']))
      relE_ipop_mean[y-1] = get_relE(rep$log_ipop_mean, log_ipop_mean)
      relE_ipop_dev[y-1] = mean(get_relE(rep$ipop_dev, ipop_dev))
      relE_R_dev[y-1] = mean(get_relE(rep$R_dev, R_dev))
      relE_R[y-1] <- mean(get_relE(rep$R, get_dwindow(R/caaInScalar, sty, y-1)))  #AEW
      relE_F[y-1] <- mean(get_relE(rep$F_full, get_dwindow(F_full, sty, y-1))) #AEW
    }

    if(mproc[m,'ASSESSCLASS'] == 'ASAP' & y > fmyearIdx-1){
      # average over each assessment time series
      relE_SSB[y-1] <- mean(get_relE(SSBnew1, SSB[(y-length(SSBnew1)+1):y]))
      relE_N[y-1] <- mean(get_relE(Nnew1,rowSums(J1N[(y-length(SSBnew1)):(y-1),])))
      relE_R[y-1] <- mean(get_relE(Rnew1, R[(y-length(SSBnew1)):(y-1)]))
      relE_F[y-1] <- mean(get_relE(Fnew1, F_full[(y-length(SSBnew1)):(y-1)]))
    }

  })

  return(out)

}
