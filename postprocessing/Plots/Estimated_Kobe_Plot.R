#####Estimated from the Stock Assessment Kobe Plot####
#Lists numbers of scenarios that you want to compare here
Scenarios<-c(5,6,7,8)
#Set working directory--where the results you want to compare are stored
wd<-"C:/Users/mmazur/Box/Mackenzie_Mazur/HCR_Sims"
#List what is being compared
comparison<-c('Ramp','P*','F-step','Constrained ramp')

####Set up files####
library(matrixStats)
library(dplyr)
library(ggrepel)
library(ggthemes)
setwd(paste(wd,"/Sim_",Scenarios[1],"/sim",sep=""))

sims <- list.files()

Freal<-matrix(NA,ncol=length(sims),nrow=20)
Fproxy<-matrix(NA,ncol=length(sims),nrow=20)
SSBestreal<-matrix(NA,ncol=length(sims),nrow=20)
SSBestproxy<-matrix(NA,ncol=length(sims),nrow=20)

for (k in 1:length(sims)){
  if (file.size(sims[k])==0){
    sims[k]<-NA}
}
sims<-na.omit(sims)

for (k in 1:length(sims)){
  load(sims[k])
  Freal[,k]<-na.omit(tail(omvalGlobal[[1]]$Fest[length(omvalGlobal[[1]]$sumCW),],22))
  SSBestreal[,k]<-na.omit(tail(omvalGlobal[[1]]$SSBest[length(omvalGlobal[[1]]$sumCW),],22))
  Fproxy[,k]<-omvalGlobal[[1]]$FPROXY[169:(length(omvalGlobal[[1]]$sumCW)-2)]
  SSBestproxy[,k]<-omvalGlobal[[1]]$SSBPROXY[169:(length(omvalGlobal[[1]]$sumCW)-2)]
}

Freal<-rowMedians(Freal,na.rm=T)
Fproxy<-rowMedians(Fproxy,na.rm=T)
Fratioreal<-Freal/Fproxy

SSBestreal<-rowMedians(SSBestreal,na.rm=T)
SSBestproxy<-rowMedians(SSBestproxy,na.rm=T)
SSBestratioreal<-SSBestreal/SSBestproxy
Year<-2019:((length(omvalGlobal[[1]]$sumCW)-169)+2017)
Dftrue<-as.data.frame(cbind(SSBestratioreal,Fratioreal,Year))
Dftrue$Scenario<-Scenarios[1]

for (m in 2:length(comparison)){
setwd(paste(wd,"/Sim_",Scenarios[m],"/sim",sep=""))

sims <- list.files()

Freal<-matrix(NA,ncol=length(sims),nrow=20)
Fproxy<-matrix(NA,ncol=length(sims),nrow=20)
SSBestreal<-matrix(NA,ncol=length(sims),nrow=20)
SSBestproxy<-matrix(NA,ncol=length(sims),nrow=20)

for (k in 1:length(sims)){
  if (file.size(sims[k])==0){
    sims[k]<-NA}
}
sims<-na.omit(sims)

for (k in 1:length(sims)){
  load(sims[k])
  Freal[,k]<-na.omit(tail(omvalGlobal[[1]]$Fest[length(omvalGlobal[[1]]$sumCW),],22))
  SSBestreal[,k]<-na.omit(tail(omvalGlobal[[1]]$SSBest[length(omvalGlobal[[1]]$sumCW),],22))
  Fproxy[,k]<-omvalGlobal[[1]]$FPROXY[169:(length(omvalGlobal[[1]]$sumCW)-2)]
  SSBestproxy[,k]<-omvalGlobal[[1]]$SSBPROXY[169:(length(omvalGlobal[[1]]$sumCW)-2)]
}

Freal<-rowMedians(Freal,na.rm=T)
Fproxy<-rowMedians(Fproxy,na.rm=T)
Fratioreal<-Freal/Fproxy

SSBestreal<-rowMedians(SSBestreal,na.rm=T)
SSBestproxy<-rowMedians(SSBestproxy,na.rm=T)
SSBestratioreal<-SSBestreal/SSBestproxy
Year<-2019:((length(omvalGlobal[[1]]$sumCW)-169)+2017)
Dftrue2<-as.data.frame(cbind(SSBestratioreal,Fratioreal,Year))
Dftrue2$Scenario<-Scenarios[m]
df<-full_join(df,Dftrue2)
}

####Kobe Plot####
library(ggplot2)
maxSSBest<-max(1.1,max(df$SSBestratioreal))
maxF<-max(1.1,max(df$Fratioreal))

for (i in 1:length(comparison)){
  Df$HCR[Df$HCR==Scenarios[i]]<-comparison[i]
}
Df$HCR<-as.factor(Df$HCR)
Df$HCR<-ordered(Df$HCR,levels=comparison)

kobe <- ggplot(df, aes(x = SSBestratioreal, y = Fratioreal)) +
  theme_bw() 
kobe <- kobe + annotate(geom = "rect", xmin = 1, xmax = maxSSBest, ymin = 0, ymax = 1, fill = "green", colour = "green", alpha = 0.5) +
  annotate(geom = "rect", xmin = 0, xmax = 1, ymin = 1, ymax = maxF, fill = "red", colour = "red", alpha = 0.5) +
  annotate(geom = "rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "yellow", colour = "yellow", alpha = 0.5) +
  annotate(geom = "rect", xmin = 1, xmax = maxSSBest, ymin = 1, ymax = maxF, fill = "yellow", colour = "yellow", alpha = 0.5) +
  geom_path(aes(linetype = HCR,colour=HCR), size = 0.3) +
  geom_point(aes(colour=HCR)) + # colour = yr
  labs(x = 'SSB/SSB MSY',
       y = 'F/F MSY') +
  xlim(0,maxSSBest)+
  ylim(0,maxF)+
  scale_color_colorblind()+
  geom_vline(xintercept=0.5, linetype='dotted')+
  theme(text=element_text(size=16),legend.position='bottom')+
  geom_text_repel(data=subset(df, Year > 2037 | Year < 2020),aes(x = SSBestratioreal, y = Fratioreal, label = Year))
kobe
