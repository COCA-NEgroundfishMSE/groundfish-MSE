# this small file controls some economic options that may vary with the mproc lines.  For example:
  # in the "validation" model runs, we use the "post" production regression, the  "pre" choice equations, post multipliers, prices.  
  # in the counterfactual model runs, we use the "pre" production regression, the  "pre" choice equations, post multipliers, prices.   
  # LandZero is unused

myvars<-c("LandZero", "CatchZero","EconType","EconName","EconData","MultiplierFile","OutputPriceFile","InputPriceFile","ProdEqn","ChoiceEqn")
econtype<-mproc[m, myvars]

econ_data_stub<-econtype$EconData

multiplier_loc<-econtype$MultiplierFile
output_price_loc<-econtype$OutputPriceFile
input_price_loc<-econtype$InputPriceFile



# you need to fix this so it flexibly reads in the vectors
production_vars<-get(paste0("production_vars_",econtype$ProdEqn))
spstock_equation<-get(paste0("spstock_equation_",econtype$ChoiceEqn))
choice_equation<-get(paste0("choice_equation_",econtype$ChoiceEqn))

#multipliers<-readRDS(file.path(econdatapath,multiplier_loc))
#outputprices<-readRDS(file.path(econdatapath,output_price_loc))
#inputprices<-readRDS(file.path(econdatapath,input_price_loc))


#Quota price coefficients
quotaprice_coefs<-readRDS(file.path(econdatapath,quotaprice_coefs_loc))
quarterly_output_prices<-as.data.table(read.csv(file.path(econdatapath,quarterly_output_price_loc), header=TRUE))
quarterly_output_prices<-split(quarterly_output_prices, by="gffishingyear")
