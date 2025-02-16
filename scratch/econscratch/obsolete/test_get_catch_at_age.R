# some code to test the function that computes catch-at-age from the   


############################################################
  #Preamble stuff that is contained in other places.
  #load in functions
  #set class to not HPCC
  #load libraries
  #declare some paths to read and save things that I'm scratchpadding
############################################################


rm(list=ls())
ffiles <- list.files(path='functions/', full.names=TRUE, recursive=TRUE)
invisible(sapply(ffiles, source))
runClass<-'local'
source('processes/loadLibs.R')


library(microbenchmark)
econsavepath <- 'scratch/econscratch'
econdatapath <- 'data/data_processed/econ'

#Setup some fake data

catch_pounds<-80000
pounds_per_kg<-2.20462
catch<-catch_pounds/pounds_per_kg

selectivity <-c(.1, .25, .35, .5, 1, 1, .8, .8, .8) 
NAA<- c(1000, 1000, 1000, 600, 100, 100, 800,1500,1500 )
kgatage<- c(1, 2.5, 3.01, 3.89, 4.25, 5.25, 6.58, 8.58, 9.25 )



end<-length(NAA)
#do the standard get_catch_at_age function, which uses NAA, weight at age, and the selectivity vector to convert landed weight to get the raw catch-at-age vector.
mycaa<-get_catch_at_age(catch_pounds/pounds_per_kg,NAA,kgatage,selectivity)

#compute total weight at age; weights corresponding to the raw catch-at-age vector, and the next period NAA weights.
NAA_weights<-NAA*kgatage
mycaa_weights<-mycaa*kgatage
next_weights<-NAA_weights - mycaa_weights

#Do first check for valid weights in the next period.  If there are any entries in next_weights that are negative, handle them.

if(any(next_weights<0)){
  fix_weight<-next_weights
  fix_weight[fix_weight>=0]<-0
  fix_counts<-fix_weight/kgatage
  end<-length(NAA)

#### fancy way


#deal with the first age class and last age class
lc<-1
if(fix_weight[lc] <0)  {
  mycaa_weights<-get_e_smear_up(mycaa_weights,fix_weight,lc)
  mycaa<-get_e_smear_up(mycaa,fix_counts,lc)
}

lc<-end
if(fix_weight[lc] <0)  {
  mycaa_weights<-get_e_smear_down(mycaa_weights,fix_weight,lc)
  mycaa<-get_e_smear_down(mycaa,fix_counts,lc)
}

#deal with the age classes that are in the middle.
# if you were better at R, you could write this to facilitate an lapply. But you're not.
for (lc in 2:(end-1)) {
  if(fix_weight[lc] <0)  {
      if (next_weights[lc-1]>0 & next_weights[lc+1]>0){
        mycaa_weights<-get_e_smear_both(mycaa_weights,fix_weight,lc)
        print(paste0("smearing both lc=",lc) )
        mycaa<-get_e_smear_both(mycaa,fix_counts,lc)
        }
    if (next_weights[lc-1]>0 & next_weights[lc+1]<=0){
      mycaa_weights<-get_e_smear_down(mycaa_weights,fix_weight,lc)
      print(paste0("smearing down lc=",lc) )
      mycaa<-get_e_smear_down(mycaa,fix_counts,lc)
      }
    if (next_weights[lc-1]<=0 & next_weights[lc+1]>0){
      mycaa_weights<-get_e_smear_up(mycaa_weights,fix_weight,lc)
      print(paste0("smearing up lc=",lc) )
      mycaa<-get_e_smear_up(mycaa,fix_counts,lc)
      }
  }
}

next_weights<-NAA_weights-mycaa_weights

}


#This should equal catch in pounds earlier
z<-rowSums(mycaa_weights)*pounds_per_kg

z
catch_pounds
