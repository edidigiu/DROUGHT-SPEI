###  COMPUTATION OF SPEI INDEX GLOBALLY  ########
#
#  Edmondo Di Giuseppe
#  24 March 2017
#
#  this file is self consistent
##################################################################
# Dataset: CRU TS $VerCRU;
# Compute SPEI following library(SPEI):
#Santiago Beguería and Sergio M. Vicente-Serrano (2013). SPEI: Calculation of the Standardised
#Precipitation-Evapotranspiration Index. R package version 1.6.
#https://CRAN.R-project.org/package=SPEI
###############################################################
if(!require(raster,lib.loc=.libPaths()[1])){install.packages("raster",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(SPEI,lib.loc=.libPaths()[1])){install.packages("SPEI",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(gdata,lib.loc=.libPaths()[1])){install.packages("gdata",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(colorspace,lib.loc=.libPaths()[1])){install.packages("colorspace",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(Hmisc,lib.loc=.libPaths()[1])){install.packages("Hmisc",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(parallel,lib.loc=.libPaths()[1])){install.packages("parallel",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
source("TrendFunctions.R")

# INTERCEPT name of file to be loaded from UNIX SCRIPT:
args <- commandArgs()
print(args)
FILEOUT <- args[6]     # filename of precipitation
FILEPET <- paste("Dati/",args[7],sep="")      #filename of potential evapotranspiration
VerCRU  <- args[8]    # version

print(FILEOUT)
print(FILEPET)
print(VerCRU)
print(paste("Outputs/SPEI/IndexTimeSeries/",VerCRU,"/",sep=""))

### Load data from local directory:
#---------------------------------
### Prec
precCRU<-brick(FILEOUT,varname="pre")
precCRU

## Pet
petCRU<-brick(FILEPET)
petCRU

#Set times::
Xtimes<-getZ(precCRU)
TS.start<-c(as.numeric(getYear(Xtimes[1])),as.numeric(getMonth(Xtimes[1])))

## PET from CRU is mm/day, thus PET data need to be multiplied by the number of days counted in each month:
ndays <- Hmisc::monthDays(Xtimes)   #as.Date(out.nc.var$dim[[3]]$vals,origin='1900-1-1'))
petCRU<-petCRU*ndays
petCRU<-setZ(petCRU,Xtimes)

###  the climatic balance precipitation minus potential evapotranspiration
balanceCRU<-precCRU-petCRU
balanceCRU
#---------------------------------

#LongTermBegin<-which(Xtimes=="1971-01-16")
#LongTermEnd<-which(Xtimes=="2000-12-16")
#---------------
####   Analysis of 1971-2000 monthly precipitation  ####
#precCRU.7100<-subset(precCRU,LongTermBegin:LongTermEnd)
#plot(mean(precCRU.7100))

#AveragedMonthlyPrec.7100<-ClinoMensili(precCRU.7100,median)
#paletta<-choose_palette()
#spplot(AveragedMonthlyPrec.7100,col.regions=paletta)
#---------------

# Set Time to balanceCRU:
balanceCRU <- setZ(balanceCRU,Xtimes)


###  SPEI COMPUTATION ####
#------------------------

###  Cycling over scale times 3, 6, 12:
for (i in c(3,4,6,12,24)) {
       tutti1<-SPEI_Raster(x=balanceCRU,filename=paste("Outputs/SPEI/IndexTimeSeries/",VerCRU,"/SPEI_",i,"_CRU.nc",sep=""),
                     na.rm=TRUE,scale=i,ts.start = TS.start,
                     ref.start = c(1950,1),ref.end = c(2010,12))

}


#------------------------

