
ie_folder_readin<-grep("^results_202",mproc$ie_source, value=TRUE)
ie_folder_readin<-unique(ie_folder_readin)

if (length(ie_folder_readin)>1) {
  stop("multiple ie_folders specified. Check mprocfile")
}
#flLst is a list that contains all the omvalGlobals. 
if (length(ie_folder_readin==1)) {
  old_name<-list.files(path=here(ie_folder_readin,"sim"),pattern="^omvalGlobal?")
  flLst<-vector("list", length(old_name))
 
  for(i in 1:length(old_name)){
    load(here(ie_folder_readin,"sim",old_name[i]))  
    flLst[[i]] <- omvalGlobal
    names(flLst[[i]]) <- names(omvalGlobal)
    rm(omvalGlobal)
      }

  old_omvalGlobal<-vector("list", length(flLst[[1]]))
  
  for(i in 1:length(flLst[[1]])){
    
    omval <- get_simcat(x=lapply(flLst, '[[', i ), along_dim=1)
    names(omval) <- names(flLst[[1]][[i]])
    
    # The "year" list element in omval is for plotting and needs to be
    # only the length of the number of years -- unlike the other categories
    # this doesn't change. So plotting doesn't get result in errors, change
    # the dimensions of this list element
    omval[['YEAR']] <- omval[['YEAR']][1:(length(omval[['YEAR']])/length(flLst))]
    
    old_omvalGlobal[[i]]<-omval
  }
  names(old_omvalGlobal) <- names(flLst[[1]])
  
  
  
  
}

# old_omvalGlobal becomes a list that stacks the entries of flLst on the first dimension, so that 
# length(old_omvalGlobal)==number of stocks  
# 




