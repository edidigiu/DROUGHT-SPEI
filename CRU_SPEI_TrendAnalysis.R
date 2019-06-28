###  ANALISYS OF SPEI TREND   ########
#
#  Edmondo Di Giuseppe
#    April, 2017
###############################################################
# 1) read SPEI(3)(4)(6)(12)(24)_(distribution)_CRU.nc data in ./Outputs/SPEI/IndexTimeSeries/X.XX/  
# 2) select scale:
#     SPEI3  ->  Jan to Dec
#     SPEI6  ->  Jan to Dec
#     SPEI12 ->  Jan to Dec
#     SPEI24 ->  Jan to Dec
# and five negative SPEI classes:
#   - moderately dry (-1>SPEI>-1.5)
#   - severely dry (-1.5>SPEI>-2) 
#   - extremely dry (SPEI< -2)
#   - extremely&severely dry (-1.5 >SPEI> -1000) 
#   - drought risk (-1 >SPEI> -1000)
# 
# 3) trend analysis for 12*4 time series listed in 2)
# 4) test of trend significance:::
#     *1  for positive trend
#     *-1 for negative trend
#     *0  for no trend OR no drought events  !!!!!!
#---------------------------------------------------------------

#Load library and Functions:
#--------------------------
if(!require(ncdf4,lib.loc=.libPaths()[1])){install.packages("ncdf4",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(raster,lib.loc=.libPaths()[1])){install.packages("raster",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(rgdal,lib.loc=.libPaths()[1])){install.packages("rgdal",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(gdata,lib.loc=.libPaths()[1])){install.packages("gdata",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}   # for getYears()
if(!require(ggplot2,lib.loc=.libPaths()[1])){install.packages("ggplot2",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(latticeExtra,lib.loc=.libPaths()[1])){install.packages("latticeExtra",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}  # for mapping raster data
if(!require(rasterVis,lib.loc=.libPaths()[1])){install.packages("rasterVis",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}   # utilities for ggplot2 library
if(!require(modifiedmk,lib.loc=.libPaths()[1])){install.packages("modifiedmk",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}   # utilities for ggplot2 library
if(!require(parallel,lib.loc=.libPaths()[1])){install.packages("parallel",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
if(!require(maptools,lib.loc=.libPaths()[1])){install.packages("maptools",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}
#if(!require(trend,lib.loc=.libPaths()[1])){install.packages("trend",repos="https://cran.stat.unipd.it/",dependencies = TRUE)}

# library(reshape2)

# load own functions
source("TrendFunctions.R")
#---------------


# INTERCEPT name of file to be loaded from UNIX SCRIPT:
args <- commandArgs()
print(args)
index <- args[6]     # type of drought index
VerCRU  <- args[7]    # version

print(index)
print(VerCRU)
(dirDATA=paste(getwd(),"/Outputs/",index,"/IndexTimeSeries/",VerCRU,"/",sep=""))


# !!! CHOICE FOR SPI:TYPE OF USED DISTRIBUTION FOE PARAMETER ESTIMATES  !!! #
#     Gamma or Pearson III  (default PearsonIII)                            #
distr.name="Pearson"
(ifelse(index=="SPEI",file.label <-"_SPEI_",file.label<-paste("_SPI_",distr.name,"_",sep="")))
#----------------


# !!! CHOICE FOR  TIME WINDOW OF TREND ANALYSIS !!! #
#                                #
TimeWindow=NULL    # specify the initial year, e.g. 1950 
#----------------


#SPEI/SPI time scale:
scaleSPEI<-c()

#Test acceptance I type error:
alpha=c(0.10,0.05)

#drought class selection:
moderateT<-c(-1.5,-1)
severeT<-c(-2,-1.5)
extremeT<-c(-1000,-2)
ExtremeSevereT<-c(-1000,-1.5)
DroughtT<-c(-1000,-1)

drought.classes<-list(moderateT,severeT,extremeT,ExtremeSevereT,DroughtT)
names(drought.classes)<-c("ModerateT","SevereT","ExtremeT","Severe+ExtremeT","DroughtT")
#------------------------------------------------


# World borders::
#--------------------------------------------
require(maptools)
#world.map <- readOGR("Dati/TM_WORLD_BORDERS_SIMPL-0.3.shp")
world.map2 <- readShapeLines("Dati/TM_WORLD_BORDERS_SIMPL-0.3.shp")
class(world.map2)
proj4string(world.map2)<-"+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
#head(world.map@data)
# require(maps)
# #Per aggiungere la mappa WORLD sui grafici:
# world.map <- maps::map("world")
# world.map.shp <-maptools::map2SpatialLines(world.map)#, proj4string=projection(precsat.raster))
# world<-maps::map("world",fill=TRUE,col="transparent", plot=F)
# p4s<-CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
# #SLworld<-map2SpatialLines(world,proj4string=p4s)     # se voglio LINEE con il dettaglio delle PROVINCE
# countries<-world$names
# SPworld<-map2SpatialPolygons(world,IDs=countries,proj4string=p4s)
#------------------------------------------------


#---------------------------------------------
#Read data  (period gen1901-decXXXX: XX months):
#---------------------------------------------

ifelse(index=="SPEI",DataList<-list.files(dirDATA,pattern = "CRU"),DataList<-list.files(dirDATA,pattern = distr.name))
for(i in 1:length(DataList)){
  
  # Exclude time scale 4 months from the analysis:
  if(DataList[i]=="SPEI_4_CRU.nc"|DataList[i]=="SPI_4_CRU.nc") {print("Exclude Time scale 4 months");next}
  
  # Identify index time scale
  N.ts=12; monthSPEI<-month.name
  if(grepl("24",DataList[i])==TRUE){scaleSPEI=24}
  if(grepl("12",DataList[i])==TRUE){scaleSPEI=12}
  if(grepl("3",DataList[i])==TRUE){scaleSPEI=3}
  if(grepl("6",DataList[i])==TRUE){scaleSPEI=6}
  print(paste(index,"time scale is:",scaleSPEI,"months"))

  # Make sub-directories for NetCDF files and plots (according to index time scale):
  (dirOUT=paste(getwd(),"/Outputs/",index,"/TrendTest/",VerCRU,"/",index,"-",scaleSPEI,sep=""))
  (dirOUT2=paste(getwd(),"/Outputs/",index,"/EventsNumber/",VerCRU,"/",index,"-",scaleSPEI,sep=""))
  if(dir.exists(dirOUT)==FALSE) dir.create(dirOUT,recursive=TRUE)
  if(dir.exists(dirOUT2)==FALSE) dir.create(dirOUT2,recursive=TRUE)
  
  (dirPLOT=paste(getwd(),"/Plots/",index,"/TrendTest/",VerCRU,"/",index,"-",scaleSPEI,sep=""))
  (dirPLOT2=paste(getwd(),"/Plots/",index,"/EventsNumber/",VerCRU,"/",index,"-",scaleSPEI,sep=""))
  if(dir.exists(dirPLOT)==FALSE) dir.create(dirPLOT,recursive=TRUE)
  if(dir.exists(dirPLOT2)==FALSE) dir.create(dirPLOT2,recursive=TRUE)
  
  # Open file for extracting vector of times:
  NC<-nc_open(paste(dirDATA,DataList[i],sep=""))
  print(paste("The file has",NC$nvars,"variables"))
  # which place has the index in the NC var list?
  place<-grep(pattern=index,names(NC$var),ignore.case = TRUE)
  v1 <- NC$var[place][[1]]
  (varsize <- v1$varsize)
  (ndims   <- v1$ndims)
  (nt <- varsize[ndims])    # Remember timelike dim is always the LAST dimension!
  (timeunit <- v1$dim[[ndims]]$units)
  (timedate <- substr(timeunit,(nchar(timeunit)-10+1),nchar(timeunit)))
  nc_close(NC)
  print(paste("Just read",DataList[i],"for extracting vector of times starting from:",timedate))
  
  Tbegin<-as.Date(strptime(timedate,format="%Y-%m-%d"))
  Tseries<-seq.Date(from=Tbegin,length.out = (nt+1),by="month")
  Tseries<-Tseries[2:length(Tseries)]     # NetCDF date format refers to the sequence of value from 0 to nt, 
                                          # we need to set from 1 to nt
  
  # Import data
  datax<-brick(paste(dirDATA,DataList[i],sep=""))
  datax<-setZ(datax,Tseries)
  names(datax)<-paste("X",Tseries,sep="")
  print("Data time series has been loaded")
  
  
  # Loop for building SPEI/SPI time series of each month #
  for (m in 1:N.ts) {
    print(paste("Month is:",month.abb[m]))
    # select single month in the dataset:
    single_seq<-seq(m,dim(datax)[3],by=12)
    #-----
    # season selection:
    datax1<-datax[[single_seq]]
    datax1<-setZ(datax1,as.Date(substr(names(datax1),2,10),format = "%Y.%m.%d"))
    #plot(datax1,2:4)
    print("Data have been subset according to month")
    
    # Subsetting the time window for the study of trend ##
    if(is.null(TimeWindow)==FALSE){
      datax1<-subset(datax1,grep(TimeWindow,getZ(datax1)):nlayers(datax1))
      print("Data have been subset according to user Time Window for trend analysis")
    }
    #-----
    
    # looping over drought classes:
    for (cl in 1:length(drought.classes)) {
      ClassName<-substr(names(drought.classes[cl]),1,(nchar(names(drought.classes[cl]))-1))
      print(paste("Class is:",ClassName))
      
      # Counting events by means of plugged-in function:
      EventsNum<-TrendSPEI_Raster(x=datax1,filename=paste(dirOUT2,"/CRU_EventsNumber_",monthSPEI[m],file.label,scaleSPEI,"_DroughtClass_",ClassName,".nc",sep = ""),
                              threshold=drought.classes[[cl]],month=m,xSum=TRUE)
      
      #----------------------------------------------
      #Maps (number of events in the entire period)::
      #----------------------------------------------
      #Set palette for events counting:
      colori<-colorRampPalette(c("lightgreen","yellow","orange","red"))(20)
      #my.at=c(0,1,5,10,15,20,25,max(getValues(EventsNum),na.rm = T))
      #myColorkey <- list(at=my.at, ## where the colors change
      #                   labels=list(at=c(0,1,5,10,15,20,25,max(getValues(EventsNum),na.rm = T)) )) ## where to print labels
      
      #Trellis:
      p<-levelplot(EventsNum,
                   layer=1,
                   main=list(paste("Cumulated number of events in ",ClassName," class, ",monthSPEI[m],file.label,scaleSPEI, " months (",
                              getYear(getZ(datax1)[1]),"-",getYear(getZ(datax1)[length(getZ(datax1))]),")",sep=""),cex=0.9),
                   interpolate=FALSE,
                   margin=F,
                   col.regions=colori,
                   contour=T,
                   #par.setting=myTheme,           
                   #at=my.at,
                   #colorkey=myColorkey,
                   xlab="Longitudine", ylab="Latitudine",
                   panel = panel.levelplot.raster
                   ) 
      p + layer(sp.lines(world.map2,col="grey",fill="transparent"))
      
      trellis.device(png,file=paste(dirPLOT2,"/CRU_EventsNumber_",monthSPEI[m],file.label,scaleSPEI,"_DroughtClass_",ClassName,".png",sep = ""),
                     width = 15, height = 14, units = "cm",res=300)
      print(p)
      dev.off()
      
      # trellis.device(pdf,file=paste(dirPLOT2,"/CRU_EventsNumber_",monthSPEI[m],file.label,scaleSPEI,"_DroughtClass_",ClassName,".pdf",sep = ""))
      # print(p)
      # dev.off()
      #------
      
      # Testing trend by means of plugged-in function:
      #----------------------------------------------
      # Looping alpha level for test
      for(a in 1:2){
        TrendTest<-TrendSPEI_Raster(x=datax1,filename=paste(dirOUT,"/CRU_TrendTest_alpha_",alpha[a],"_",monthSPEI[m],file.label,scaleSPEI,"_DroughtClass_",ClassName,".nc",sep = ""),
                                alpha=alpha[a],threshold=drought.classes[[cl]],month=m,xSum=FALSE)
        
        
        names(TrendTest)<-c("Nhpp","MK","MK-classic","Diff")
        # change colors for Mk e Mk-classic
        TrendTest[[2]]<-TrendTest[[2]]*(-1)
        TrendTest[[3]]<-TrendTest[[3]]*(-1)
        
        #Maps (time-trend)::
        #Trellis
        colori<-colorRampPalette(c("green","lightgrey","red"))
        my.at=c(-1,-0.35,0.35,1)
        myColorkey <- list(at=my.at, ## where the colors change
                           labels=list(at=c(-0.70,0,0.70),labels=c("neg","no sign","pos"))) ## where to print labels
        
        p<-levelplot(TrendTest,
                     layer=c(1,2,3),
                     main=list(paste("Trend result in ",ClassName," class at alpha=",alpha[a],", ",monthSPEI[m],file.label,scaleSPEI, " months (",
                                getYear(getZ(datax1)[1]),"-",getYear(getZ(datax1)[length(getZ(datax1))]),")",sep=""),
                               cex=0.9),
                     interpolate=FALSE,
                     margin=F,
                     col.regions=colori(3),
                     contour=T,
                     #par.setting=myTheme,           
                     at=my.at,
                     colorkey=myColorkey,
                     xlab="Longitudine", ylab="Latitudine",
                     panel = panel.levelplot.raster
        ) 
        p + layer(sp.lines(world.map2,col="grey",fill="transparent"))
        
        trellis.device(png,file=paste(dirPLOT,"/CRU_TrendTest_alpha",alpha[a],"_",monthSPEI[m],file.label,scaleSPEI,"_DroughtClass_",ClassName,".png",sep = ""),
                       width = 15, height = 14, units = "cm",res=300)
        print(p)
        dev.off()
        
        #------
      } #closing "a" in alpha levels
      
    } #closing "cl" in drought.classes
  } #closing "m" in monthsSPEI
} #closing "i" in DataList



