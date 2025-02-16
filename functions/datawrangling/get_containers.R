# Script to create containers (necessary because the main
# script uses loops that it fills)

get_containers <- function(stockPar){
  
  yxage = matrix(NA, nrow=nyear, ncol=stockPar$nage)
  yx0 = rep(NA, nyear)
  est = matrix(NA,nyear,54)
  
  nomyear = nyear - (stockPar$ncaayear + fyear + nburn)
  nmproc = nrow(mproc)
  
  save_vector_ann = array(data = NA,
                          dim = c(nrep, nmproc, nyear),
                          dimnames = list(paste0('rep', 1:nrep), 
                                          paste0('mproc', 1:nmproc),
                                          paste0('nyear', 1:nyear)))
  
  out <- list(

    # Containers that save the simulation data
    J1N = yxage,
    CN = yxage,
    CN_temp = yxage,
    codCW = yxage,
    codCW2 = yx0,
    CW = yxage,
    IN = yxage,
    IJ1= yxage,
    laa = yxage,
    waa = yxage,
    Z = yxage,
    slxC = yxage,
    slxI = yxage,
    mat = yxage,
    F_full = yx0,
    F_fullAdvice = yx0,
    ACL = yx0,
    R = yx0,
    Rhat = yx0,
    N=yx0,
    SSB = yx0,
    RPmat = matrix(NA, nrow=nyear, ncol=4,
                   dimnames = list(paste0(1:nyear), 
                                   c('FRefP', 'BRefP','FRefPT', 'BRefPT'))),
    OFdStatus = yx0,
    mxGradCAA = yx0,
    OFgStatus = yx0,
    natM = yx0,
    
    # Containers that have corresponding outputs for the
    # assessment model
    
    # catch weight
    sumCW = yx0,
    obs_sumCW = yx0,
    
    # total survey index in numbers
    sumIN = yx0,
    obs_sumIN = yx0,
    
    # total survey index in weight (if obs_sumIW is needed see note in
    # get_indexData comments)
    sumIW = yx0,
    obs_sumIW = yx0,
    
    # catch proportions-at-age
    paaCN = yxage,
    obs_paaCN = yxage,
    
    # survey proportions-at-age
    paaIN = yxage,
    obs_paaIN = yxage,
    
    # fishing effort
    effort = yx0,
    obs_effort = yx0,
    
    # Stock assessment model results
    relE_qI = yx0,
    relE_qC = yx0,
    relE_selCs0 = yx0,
    relE_selCs1 = yx0,
    relE_ipop_mean = yx0,
    relE_ipop_dev = yx0,
    relE_R_dev = yx0,
    relE_SSB = yx0,
    relE_N= yx0,
    relE_IN = yx0,
    relE_R = yx0, #AEW
    relE_F = yx0, #AEW
    SSB_cur = yx0, #AEW
    conv_rate = yx0,#MDM
    Mohns_Rho_SSB = yx0,
    Mohns_Rho_N = yx0,#MDM
    Mohns_Rho_F = yx0,#MDM
    Mohns_Rho_R = yx0,#MDM
    mincatchcon = yx0, #MDM
    relTermE_SSB = NA,#MDM
    relTermE_CW = NA,#MDM
    relTermE_IN = NA,#MDM
    relTermE_qI = NA,#MDM
    relTermE_R = NA,#MDM
    relTermE_F = NA,
    SSBest = est, 
    Fest = est, 
    Catchest = est, 
    Rest = est,
    
    # Econ model containers
    # Total Weight of catch
    econCW= yx0, 
    
    # container to hold operating/assessment model results
    # (operating model-assessment model comparison)
    
    dn_rep = paste0('rep', 1:nrep),
    dn_omyear = paste0('year', 1:nomyear),
    dn_mproc = paste0('mproc', 1:nmproc),
  
    omval = list(
      N = save_vector_ann,
      SSB = save_vector_ann,
      R = save_vector_ann,
      F_full = save_vector_ann,
      F_fullAdvice = save_vector_ann,
      ACL = save_vector_ann,
      econCW= save_vector_ann, 
      sumCW = save_vector_ann,
      annPercentChange = save_vector_ann, #cheap ... not really vector.
      meanSizeCN = save_vector_ann,
      meanSizeIN = save_vector_ann,
      FPROXY = save_vector_ann,
      SSBPROXY = save_vector_ann,
      FPROXYT = save_vector_ann,
      SSBPROXYT = save_vector_ann,
      FPROXYT2 = save_vector_ann,
      SSBPROXYT2 = save_vector_ann,
      SSBRATIO = save_vector_ann,
      SSBRATIOT = save_vector_ann,
      SSBRATIOT2 = save_vector_ann,
      FRATIO = save_vector_ann,
      FRATIOT = save_vector_ann,
      FRATIOT2 = save_vector_ann,
      OFdStatus = save_vector_ann,
      mxGradCAA = save_vector_ann,
      relE_qI = save_vector_ann,
      relE_qC = save_vector_ann,
      relE_selCs0 = save_vector_ann,
      relE_selCs1 = save_vector_ann,
      relE_ipop_mean = save_vector_ann,
      relE_ipop_dev = save_vector_ann,
      relE_R_dev = save_vector_ann,
      relE_SSB = save_vector_ann,
      relE_N = save_vector_ann,
      relE_IN = save_vector_ann,
      relE_R = save_vector_ann, #AEW
      relE_F = save_vector_ann, #AEW
      OFgStatus = save_vector_ann, #AEW
      SSB_cur = save_vector_ann, #AEW
      natM = save_vector_ann, #AEW
      conv_rate = save_vector_ann, #MDM
      Mohns_Rho_SSB = save_vector_ann,
      Mohns_Rho_N = save_vector_ann,#MDM
      Mohns_Rho_F = save_vector_ann,#MDM
      Mohns_Rho_R = save_vector_ann,#MDM
      mincatchcon = save_vector_ann, #MDM
      relTermE_SSB = save_vector_ann,#MDM
      relTermE_CW = save_vector_ann,#MDM
      relTermE_IN = save_vector_ann,#MDM
      relTermE_qI = save_vector_ann,#MDM
      relTermE_R = save_vector_ann,#MDM
      relTermE_F = save_vector_ann,
      SSBest = est,
      Fest = est,
      Catchest = est,
      Rest = est
    )
    
  )
  
  return(out)

}

