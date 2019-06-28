###  COMPUTATION OF SPI INDEX GLOBALLY  ########
#
#  Edmondo Di Giuseppe
#  24 March 2017
#
#  this file is self consistent
##################################################################
# Dataset: CRU TS $VerCRU;
# Compute SPI following library(SPEI):
#Santiago Beguería and Sergio M. Vicente-Serrano (2013). SPEI: Calculation of the Standardised
#Precipitation-Evapotranspiration Index. R package version 1.6.
#https://CRAN.R-project.org/package=SPEI
###############################################################
if(!require(raster,lib.loc=.libPaths()[1])){install.packages("raster",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(SPEI,lib.loc=.libPaths()[1])){install.packages("SPEI",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(gdata,lib.loc=.libPaths()[1])){install.packages("gdata",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(colorspace,lib.loc=.libPaths()[1])){install.packages("colorspace",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(parallel,lib.loc=.libPaths()[1])){install.packages("parallel",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
source("TrendFunctions.R")


# INTERCEPT name of file to be loaded from UNIX SCRIPT:
args <- commandArgs()
print(args)
FILEOUT <- args[6]     # filename of precipitation
VerCRU  <- args[7]    # version

print(FILEOUT)
print(VerCRU)
print(paste("Outputs/SPI/IndexTimeSeries/",VerCRU,"/",sep=""))


## Load data from local directory:
#---------------------------------
## Prec
precCRU <- brick(FILEOUT,varname="pre")

#---------------------------------

#Set times::
Xtimes<-getZ(precCRU)
TS.start<-c(as.numeric(getYear(Xtimes[1])),as.numeric(getMonth(Xtimes[1])))
#LongTermBegin<-which(Xtimes=="1971-01-16")
#LongTermEnd<-which(Xtimes=="2000-12-16")
#---------------
####   Analysis of 1971-2000 monthly precipitation  ####
#precCRU.7100<-subset(precCRU,LongTermBegin:LongTermEnd)
#plot(mean(precCRU.7100))

#AveragedMonthlyPrec.7100<-ClinoMensili(precCRU.7100,median)
## paletta<-choose_palette()
## spplot(AveragedMonthlyPrec.7100,col.regions=paletta)
#---------------

###  SPI COMPUTATION ####
#------------------------

###  Cycling over scale times 3, 6, 12:
Distributions=c("Gamma","PearsonIII")
for (i in c(3,4,6,12,24)) {
  for (d in 1:2){
       tutti1<-SPI_Raster(x=precCRU,filename=paste("Outputs/SPI/IndexTimeSeries/",VerCRU,"/SPI_",i,"_CRU_",Distributions[d],".nc",sep=""),
                     na.rm=TRUE,scale=i,ts.start = TS.start,
                     ref.start = c(1950,1),ref.end = c(2010,12),
		                  distribution=Distributions[d])
       
       # ### DA AGGIUSTARE IL NUMERO DI ELEMENTI IN USCITA:       
       # tutti1_coeffs<-SPI_Raster_coefficients(x=smallPrec,filename=paste("Outputs/SPI/IndexTimeSeries/",VerCRU,"/SPI_coefficients",i,"_CRU_",Distributions[d],".nc",sep=""),
       #                     na.rm=TRUE,scale=i,ts.start = TS.start,
       #                     ref.start = c(1961,1),ref.end = c(2010,12),
       #                      distribution=Distributions[d])

  }
}

#plot(min(tutti1,na.rm=T))

#------------------------

