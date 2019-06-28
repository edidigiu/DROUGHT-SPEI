##### PLOTS FOR PAPER  ####
#
#  Sara Quaresima & Edmondo Di Giuseppe
#    April, 2017
###############################################################
# 1) select file with data 
# 2) compute frequency of cases where MK trend is (-1) and Nhpp trend is 1 (increasing drought events for both):
# 3) save data.frames containing frequencies (one for each SPEI-time scale):
#--------------------------------------------------------------

# Load libraries
if(!require(raster,lib.loc=.libPaths()[1])){install.packages("raster",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(tidyverse,lib.loc=.libPaths()[1])){install.packages("tidyverse",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(lattice,lib.loc=.libPaths()[1])){install.packages("lattice",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}


# Declare variables:
SPEIdir<-c("SPEI-12", "SPEI-3", "SPEI-6", "SPEI-24")
SPEIfile<-c("SPEI_12", "SPEI_3", "SPEI_6", "SPEI_24")
DroughtClass<-c("Drought","Moderate","Severe","Extreme","Severe+Extreme")
month<-month.name
alpha<-c("alpha_0.05","alpha_0.10")
alphaFILE<-c("alpha_0_05","alpha_0_10")
path_data<-paste0(getwd(), "/Outputs/SPEI/TrendTest/4.03/")
#------------------

# per le prove in locale:
index="SPEI"      # questo verrà inserito qui quando si lancia il file di shell 
VerCRU="4.03"     # questo verrà inserito qui quando si lancia il file di shell 
aa=3
bb=1
cc=9
dd=1


# Create directory where to save plots for paper:
(dirOUT=paste(getwd(),"/Plots/",index,"/Plots4Paper/",VerCRU,"/",sep=""))
if(dir.exists(dirOUT)==FALSE) dir.create(dirOUT,recursive=TRUE)


######    IMPORT DATA    ###########
# loop over index time scale
for(aa in 1:length(SPEIdir))
{
  print(SPEIdir[aa])
  print(SPEIfile[aa])

  # loop over alpha:
  for(bb in 1:length(alpha))
  {
    print(alpha[bb])  
    
    # place for storaging frequencies (one for each SPEI-time scale):
    COUNTs<-data.frame(matrix(NA,nrow = length(DroughtClass)*12,ncol = 3))
    names(COUNTs)<-c("ClassName","Month","Freq")

    
    ind=1      #rep(1:5,each=12)
    # loop over class
    for(dd in 1:length(DroughtClass))
    {
      print(DroughtClass[dd])

      # place for storaging  relative frequencies of MK and Nhpp for each trend signal, i.e. POS, No sign, NEG (one for each SPEI-time scale):
      COUNTs2<-data.frame(matrix(NA,nrow = 2*12,ncol = 5))
      names(COUNTs2)<-c("Model","Month","Pos","NoSign","Neg")
      COUNTs2$Month<-rep(1:12, each=2)
      # loop over month
      ind2=1
      for(cc in 1:length(month))
      {
        print(month[cc])      
      
        fileSPEI<-paste0(path_data, SPEIdir[aa], "/CRU_TrendTest_",alpha[bb], "_", month[cc], "_", SPEIfile[aa], "_DroughtClass_", DroughtClass[dd], ".nc")
        
        # import data:
        datax<-brick(fileSPEI)
        
        ### !!! INSERIRE QUI IL CODICE PER RIFARE LE MAPPE CON I COLORI CORRETTI
        ###  !!!  CAMBIARE GLI INDICI DEI CURSORI NEL NOME DEL FILE GENERATO 
        
        # subset layers 1 (Nhpp) and 2 (MK)
        datax1<-subset(datax,1:2)
        names(datax1)<-c("Nhpp","MK")
        
        datax2<-datax1
        datax2[[1]] <- datax2[[1]]*(-1)
        datax2[[2]] <- datax2[[2]]*1
        
        ###  COUNTs1   #####
        # cross-tabulate layer.1 vs layer.2
        (tab<-crosstab(datax1, digits=0, long=TRUE, useNA=FALSE, progress="text"))

        # frequency of cases where MK trend is (-1) and Nhpp trend is 1 (increasing drought events for both):
        count<-tab[which(tab$MK==(-1) & tab$Nhpp==1),"Freq"]

        # Insert into storage
        COUNTs[ind,1]<-DroughtClass[dd]
        COUNTs[ind,2]<-cc
        COUNTs[ind,3]<-count


        ####  COUNTs2    ######
        freqX<-freq(datax2)
        calcPerc<-function(x){x<-data.frame(x);x<-x[-which(is.na(x$value)),];x<-cbind(x,perc=round(x$count/sum(x$count)*100,1))}
        (perc<-lapply(freqX,calcPerc))
        
        
        # Insert into storage
        COUNTs2[ind2,1]<-names(perc)[1]
        COUNTs2[ind2+1,1]<-names(perc)[2]
        COUNTs2[ind2,3:5]<-rev(unlist(perc[["Nhpp"]]["perc"]))
        COUNTs2[ind2+1,3:5]<-rev(unlist(perc[["MK"]]["perc"]))
        
      ind2=ind2+2  
      ind=ind+1          
      }    # mm months
      
      # save(COUNTs2,file = paste0(SPEIfile[aa],"_",DroughtClass[dd],"_",alphaFILE[bb],".RData"))
      
      
      # Circular plot  for relative frequencies of MK and Nhpp for each trend signal, i.e. POS, No sign, NEG
      source("Circular_Barplot2.R")
      trellis.device(png,file=paste(dirOUT,"/CircularPlot2_",SPEIfile[aa],"_",DroughtClass[dd],"_",alpha[bb],".png",sep = ""),
                     width = 18, height = 19, units = "cm",res=300)
      print(p)
      dev.off()
      
    }   # dd DroughtClass 
    
    ####  !!! INSERIRE QUI IL CODICE PER GENERARE IL GRAFICO  !!!
    #  ORA SALVA UN OGGETTO PER LE PROVE, POI CANCELLARE:
    # save(COUNTs,file = paste0(SPEIfile[aa],"_",alphaFILE[bb],".RData"))
    
    # Circular plot  for cases when MK = (-1)
    source("Circular_Barplot.R")
    trellis.device(png,file=paste(dirOUT,"/CircularPlot_",SPEIfile[aa],"_",alpha[bb],".png",sep = ""),
                   width = 18, height = 19, units = "cm",res=300)
    print(p)
    dev.off()
  
    
    
    
  }  # bb alpha
}  # aa SPEI-