

# Driver function to create output plots from the simulation
# 
# x: list of output for plots (i.e., simlevelresults)
# 
# dirIn: simulation directory to grab specific examples for
#        particular plots (e.g., temperature time series)
# dirOut : place to store the outputs
# boxnames, rpnames, trajnames: performance measures you want to plot




get_SimLevelplots <- function(x, dirIn, dirOut, boxnames, rpnames, trajnames,breakyears=plotBrkYrs){
  
  with(x, {
    # load some of the necessary variables for plotting by running the
    # setup file.
    source(file.path(ResultDirectory,"set_om_parameters_global.R"), local=TRUE)
    source('processes/genAnnStructure.R', local=TRUE)
    

    # Year before the management period to start the plots
    py0 <- 37 #5
    
    # Index for years that will be plotted for trajectories and such
    pyidx <- (fmyearIdx-py0+1):length(yrs)
    nm <- names(x)
    # ny <- dim(x[[i]])[3]

    bxidx <-which(nm %in% boxnames)    
    rpidx <- which(nm %in% rpnames)
    trajidx <-which(nm %in% trajnames)


    #### Performance measure plots ####

    # Identify break points for selecting years to produce for each of the
    # boxplots and also names for each of the categories for printing
    brkYrsIdx <- breakyears + fmyearIdx
    brkYrsIdxExt <- c(0, brkYrsIdx, nyear)
    brkYrsNames <- yrs[c(1, brkYrsIdxExt)]
    brkYrsNames2 <- sapply(2:length(brkYrsNames), function(x) 
      paste(brkYrsNames[x-1], brkYrsNames[x], sep='-'))
    
    yearID <- cut(1:nyear, breaks=brkYrsIdxExt, labels=brkYrsNames2)
    
    if(plotBP){
      
      dir.create(file.path(dirOut, "boxplot"), showWarnings=FALSE)
      
      
      # Create the boxplots
      for(i in bxidx){
        for(j in 2:length(brkYrsNames2)){
          tempIdx <- brkYrsNames2[j] == yearID
          tempDat <- x[[i]][,,tempIdx, drop=FALSE]
          # If calculating annual percentage change need to do this calculation
          # on the same temporal scales as the divisions. This is an aggregate
          # quantity so just repeat it over years so that the container is the
          # correct shape when moving it into the boxplot.
          if(nm[i] == 'annPercentChange'){
            tempCW <- x[['sumCW']][,,tempIdx, drop=FALSE]
            tempDatUnit <- apply(tempCW, 1:2, get_stability)
            tempDat <- array(data=tempDatUnit, dim=dim(tempCW))
            dimnames(tempDat) <- dimnames(tempCW)
          }
          jpeg(file.path(dirOut, "boxplot", paste0(nm[i],"_", brkYrsNames2[j], ".jpg")))
          
            if(all(is.na(tempDat))){
              plot(0)
            }else{
              working_ylab<-paste(nm[i],brkYrsNames2[j])
              get_box(x=tempDat, ylab=working_ylab)
            }
          dev.off()
        }
      }
    }

    
    ###################################################
    # I have not coded this yet. not likely to work.
    ###################################################
    
    if(plotDrivers){
      
      # Get diagnostic plots that show (1) the temperature history; (2) the
      # growth models (with temperature); and (3) the recruitment models
      # (with temperature)
    
      #### Temperature time series ####
      
      # Time-series temperature plot
      jpeg(paste0(dirOut, 'tempts.jpg'),
           width=480*1.75, height=480, pointsize=12*1.5)
        get_tempTSPlot(temp = temp[yrs_temp %in% yrs], yrs = yrs,
                       fmyear=fmyear, ftyear=yrs[nburn+1])
      dev.off()
     
      #### Growth ####
      # Plot describing how growth changed over time
      jpeg(paste0(dirOut, 'laa.jpg'),
           width=480*1.75, height=480, pointsize=12*1.5)
        ptyridx <- fmyearIdx:length(yrs)
        get_laaPlot(laa_par=laa_par, laa_typ=laa_typ, laafun=get_lengthAtAge, 
                    ages=fage:(ceiling(1.5*page)), Tanom=Tanom[pyidx], 
                    ptyrs=yrs[pyidx])
      dev.off()
      
      # # Plot describing how average recruitment changed over time
      jpeg(paste0(dirOut, 'SR.jpg'),
           width=480*1.75, height=480, pointsize=12*1.5)
  
        ptyridx <- fmyearIdx:length(yrs)
        get_SRPlot(par=Rpar, type=R_typ, stock=stockEnv, 
                   Tanom=Tanom[ptyridx],
                    ptyrs=yrs[ptyridx])
      dev.off()
      
      
      #### Selectivity plots ####
      
      par(mar=c(4.5,4.5,1.5,1.5))
      
      # age-based selectivity plot
      jpeg(paste0(dirOut, 'slxAge.jpg'),
           width=480*1.5, height=480, pointsize=12*1.5)
      
        get_slxPlot(ages = fage:page, type = 'age', 
                    laa_typ = laa_typ, laa_par = laa_par, 
                    selC_typ = selC_typ, selCpar = selC, 
                    TAnom = mean(Tanom[fmyearIdx:length(Tanom)]))
      dev.off()
      
      # length-based selectivity plot
      jpeg(paste0(dirOut, 'slxLength.jpg'),
           width=480*1.5, height=480, pointsize=12*1.5)
      
        get_slxPlot(ages = fage:page, type = 'length', 
                    laa_typ = laa_typ, laa_par = laa_par, 
                    selC_typ = selC_typ, selCpar = selC, 
                    TAnom = mean(Tanom[fmyearIdx:length(Tanom)]))
      dev.off()
      
      
    } 
    
    ##########################################################
    #### Trajectories of OM values ####
    ###################################################
    
    dir.create(file.path(dirOut, 'Traj'), showWarnings=FALSE)
    
    # only make a few trajectories so you don't get so many plots
    repidx <-sample(1:dim(x[[trajidx[1]]])[1], 
                    size=min(1, dim(x[[trajidx[1]]])[1]))
  
    #Loop over the PMs you want to plot.
    
    for(i in trajidx){
      tempPM <- x[[i]]
      PMname <- nm[i]
      
      # Calculate a range for the boxplot y axes. In order to do this need
      # to run through the loop first and calculate all the boxplot stats.
      bpstats <- list()
      for(mp in 1:dim(tempPM)[2]){
        tempPMmp <- tempPM[,mp,pyidx]
        bpstats[[mp]] <- boxplot(x = tempPMmp, plot=FALSE)$stats
      }
      
      if(all(is.na(unlist(bpstats)))){
        next
      }
      
      # Now get the range of the statistics to use in the loop (boxplots).
      yrgbx <- range(unlist(bpstats), na.rm=TRUE)
      
      # Get y range for common axes among the reps (simulation trajectories)
      yrgrsim <- range(tempPM[repidx,,], na.rm=TRUE)
   
      # Account for 0-1 nature of binary variabiles (e.g., overfished status)
      if(is.na(yrgbx[1])){
        yrgbx <- c(0, 1)
      }
      
      dir.create(file.path(dirOut, 'Traj', PMname), showWarnings=FALSE)
      for(mp in 1:dim(tempPM)[2]){
        
        # Simplify the references
        tempPMmp <- tempPM[,mp,pyidx]
        
        if(all(is.na(tempPMmp))){
          next
        }
        ###################################################
        #### END Trajectories of OM values ####
        ###################################################
        
        
       # Doesn't work

        if(plotTrajBox){

          # First do a general boxplot of the trajectory over years
          jpeg(paste0(dirOut, 'Traj/', PMname, '/boxmp', mp, '.jpg'),
               width=480*1.75, height=480, pointsize=12*1.5)
            
            par(mar=c(4,4,1,1))
    
            get_tbxplot(x = tempPMmp, PMname=PMname, yrs=yrs[pyidx],
                        printOutliers=FALSE, yrg=yrgbx, fmyear=yrs[fmyearIdx])
          
          dev.off()
        }
        ###################################################

        # Plot individual trajectories
        # Doesn't work
        ###################################################
        if(plotTrajInd){
          # Do (up to) 5 trajectories as examples
          for(r in repidx){
            
            jpeg(file.path(dirOut,"Traj", PMname,paste0("mp", mp, "rep", r, ".jpg")),
                 width=480*1.75, height=480, pointsize=12*1.5)
            
              get_tplot(x=tempPMmp[r,], yrs = yrs[pyidx], 
                        mpName=paste('MP', mp), 
                        PMname=PMname, ylim=yrgrsim, fmyear=yrs[fmyearIdx])
              # plot(tempPM[r,mp,], type='o')
            
            dev.off()
            
          }
        }
        ###################################################
        ###################################################
        
        
      }
      
      #Works
      
      if(plotTrajSummary){
        # Trajectories for the medians of each MP over time
        
        # Get the means of each performance measure over time
        # if(nm[i] == 'OFdStatus' | nm[i] == 'F_Full'){
          mpMean <- apply(tempPM[,,pyidx, drop=FALSE], c(2,3), mean, na.rm=TRUE)
        # }else{
          # mpMed <- apply(tempPM[,,pyidx, drop=FALSE], c(2,3), median, na.rm=TRUE)
        # }
        
        if(all(is.na(mpMean))){
          next
        }
        
        # Make the plot
        jpeg(file.path(dirOut, "Traj", PMname, "SIM_MPMeanTraj.jpg"),
             width=480*1.75, height=480, pointsize=12*1.5)
          par(mar=c(4,4,1,1))
          
          # Jitter the overfished status if necessary so you can see the 
          # trajectory
          if(nm[i] == 'OFdStatus'){
            mpMean <- jitter(mpMean, amount=0.01)
          }
          get_mpMeanTraj(mpMeanMat = mpMean, x=yrs[pyidx], ylab=nm[i], 
                        fmyear=yrs[fmyearIdx])
          
        dev.off()
       # if(nrow(mpMean)== 1 & runClass == 'HPCC' & nm[i]=='SSB'|nrow(mpMean)== 1 & runClass == 'HPCC' & nm[i]=='R'|nrow(mpMean)== 1 & runClass == 'HPCC' & nm[i]=='F_full'){
        
      #  jpeg(paste0(dirOut, 'Traj/', PMname, '/MPMeanTrajwithEst.jpg'),
      #       width=480*1.75, height=480, pointsize=12*1.5)
      #  par(mar=c(4,4,1,1))
      #  get_mpMeanTrajwithEst(mpMeanMat = mpMean, x=yrs[pyidx], nm=nm, 
      #                 fmyear=yrs[fmyearIdx])
        
      #  dev.off()
      # }
      }
      
    }
    
    
    
    
  })
}







