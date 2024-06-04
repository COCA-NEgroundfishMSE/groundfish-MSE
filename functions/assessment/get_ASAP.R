##################################################################################
### function to modify Age Structured Assessment Program (ASAP) .dat file, run executable, and produce results object
###
get_ASAP <- function(stock){

  out <- within(stock, {

    # read in assessment .dat file and modify accordingly
    dat_file <- ReadASAP3DatFile(paste('assessment/ASAP/', stockName, ".dat", sep = ''), quiet=TRUE)

    ### modify for each simulation/year

    #start year;
    dat_file$dat$year1 <- fmyearIdx - ncaayear
    styear <- fmyearIdx - ncaayear

    #Change start years below to use moving window
    #dat_file$dat$year1 <- y - ncaayear
    #styear <- y - ncaayear

    #end year
    if(mproc[m,'Lag'] == 'TRUE'){
    endyear <- y-2
    }
    else if(mproc[m,'Lag'] == 'FALSE'){
    endyear <- y-1
    }

    #number of years in assessment
    N_rows <- length(styear:endyear)
    dat_file$dat$n_years <- N_rows

    #natural mortality
    dat_file$dat$M <- matrix(get_dwindow(natM, styear, endyear), nrow = N_rows, ncol = page)
    if (M_mis==TRUE){#If there is a natural mortality missepcification, the stock assessment will assume that M is the value in M_mis_val
    dat_file$dat$M <- matrix(M_mis_val, nrow = N_rows, ncol = page)
    }

    #maturity-at-age
    dat_file$dat$maturity <- matrix(get_dwindow(mat, styear, endyear), nrow = N_rows)

    #WAA matrix
    dat_file$dat$WAA_mats <-matrix(get_dwindow(waa, styear, endyear), nrow = N_rows)

    if(waa_mis==TRUE){#If there is a weight-at-age misspecification, the stock assessment will assume that weight at age was constant overtime (the first vector in the matrix).
      dat_file$dat$WAA_mats<-t(replicate(N_rows,waa[1,]))
    }

    #selectivity block (single block setup)
    dat_file$dat$sel_block_assign <- matrix(1, nrow = N_rows, 1)

    #catch-at-age proportions and sum catch weight
    dat_file$dat$CAA_mats <- cbind(get_dwindow(obs_paaCN, styear, endyear), get_dwindow(obs_sumCW, styear, endyear))

    #discards - need additional rows even if not using
    dat_file$dat$DAA_mats <- matrix(0, nrow = N_rows, ncol = page + 1)

    #release - also need additional rows if not using
    dat_file$dat$prop_rel_mats <- matrix(0, nrow = N_rows, ncol = page)

    #index data; sum index value, observation error, proportions-at-age, sample size
    dat_file$dat$IAA_mats <- cbind(seq(styear,endyear), get_dwindow(obs_sumIN, styear, endyear), rep(oe_sumIN, N_rows), get_dwindow(obs_paaIN, styear, endyear), rep(oe_paaIN, N_rows)) #year, value, CV, by-age, sample size

    #recruitment CV
    dat_file$dat$recruit_cv <- matrix(pe_RSA, nrow = N_rows, 1)

    #catch CV
    dat_file$dat$catch_cv <- matrix(0.05, nrow = N_rows, 1)

    #discard CV - need additional years even if not using
    dat_file$dat$discard_cv <- matrix(0, nrow = N_rows, 1)

    #catch effective sample size
    dat_file$dat$catch_Neff <- matrix(oe_paaCN, nrow = N_rows, 1)

    #discard ESS (even if not using)
    dat_file$dat$discard_Neff <- matrix(0, nrow = N_rows, 1)

    if(mproc[m,'Lag'] == 'TRUE'){
    dat_file$dat$nfinalyear <- y-1
    }
    else if(mproc[m,'Lag'] == 'FALSE'){
    dat_file$dat$nfinalyear <- y
    }

    dat_file$dat$proj_ini <- c((y), -1, 3, -99, 1)
    dat_file$dat$R_avg_start <- styear
    dat_file$dat$R_avg_end <- endyear - 10

    if (Sys.info()['sysname'] == "Windows") {

      # save copy of .dat file by stock name, nrep, and sim year
      WriteASAP3DatFile(fname = paste('assessment/ASAP/', stockName, '_', r, '_', y,'.dat', sep = ''),
                        dat.object = dat_file,
                        header.text = paste(stockName, 'Simulation', r, 'Year', y, sep = '_'))

      # write .dat file needs to have same name as exe file
      WriteASAP3DatFile(fname = paste('assessment/ASAP/ASAP3.dat', sep = ''),
                        dat.object = dat_file,
                        header.text = paste(stockName, 'Simulation', r, 'Year', y, sep = '_'))

      # Run the ASAP assessment model
      asapEst <- try(system('assessment/ASAP/ASAP3.exe', show.output.on.console = FALSE))

      # Read in results
      res <- dget('assessment/ASAP/ASAP3.rdat')

      # save .Rdata results from each run
      saveRDS(res, file = paste('assessment/ASAP/', stockName, '_', r, '_', y,'.rdat', sep = ''))

      # save .par file
      #file.copy("asap3.par", paste('assessment/ASAP/', stockName, '_', r, '_', y,'.par', sep = ""), overwrite = TRUE)

    }

    if (Sys.info()['sysname'] == "Linux") {

      # save copy of .dat file by stock name, nrep, and sim year
      WriteASAP3DatFile(fname = paste(rundir, '/', stockName, '_', r, '_', y,'.dat', sep = ''),
                        dat.object = dat_file,
                        header.text = paste(stockName, 'Simulation', r, 'Year', y, sep = '_'))

      # write .dat file needs to have same name as exe file
      WriteASAP3DatFile(fname = paste(rundir, '/ASAP3.dat', sep = ''),
                        dat.object = dat_file,
                        header.text = paste(stockName, 'Simulation', r, 'Year', y, sep = '_'))

      tempwd <- getwd()
      setwd(rundir)
      if(runClass =="HPCC"){
        asapEst<- try(system("singularity exec $WINEIMG wine ASAP3.EXE", wait = TRUE))
      } else if (runClass =="neptune" | runClass=="mleeContainer"){
        asapEst<- try(system("./ASAP3", intern=TRUE, wait = TRUE,ignore.stdout = TRUE, ignore.stderr = TRUE))
      }
      while (!file.exists('ASAP3.rdat')) {
        Sys.sleep(1)
      }

      # Read in results
      res <- dget('ASAP3.rdat')
      
      # save .Rdata results from each run
      saveRDS(res, file = paste(rundir, '/', stockName, '_', r, '_', y,'.rdat', sep = ''))
      
      #save .par file
      #file.copy("asap3.par", paste(rundir, '/', stockName, '_', r, '_', y,'.par', sep = ""), overwrite = TRUE)

      setwd(tempwd)

    }

  })
  
  return(out)

}
