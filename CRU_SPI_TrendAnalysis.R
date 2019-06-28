###  ANALISYS OF SPI TREND   ########
#
#  Edmondo Di Giuseppe
#    April, 2017
###############################################################
# 1) read SPI(3)(4)(6)(12)_(distribution)_CRU.nc data in /Dati  (period gen1901-dec2015: 1380 months)
# 2) select seasons:
#     SPI3  ->  Jan to Dec
#     SPI6  ->  Jan to Dec
#     SPI12 ->  Jan to Dec
# and five negative SPI classes:
#   - moderately dry (-1>SPI>-1.5)
#   - severely dry (-1.5>SPI>-2) 
#   - extremely dry (SPI< -2)
#   - extremely&severely dry (-1.5 >SPI> -1000) 
#   - drought risk (-1 >SPI> -1000)
# 
# 3) trend analysis for 12*3 time series listed in 2)
# 4) test of trend significance:::
#     *1  for positive trend
#     *-1 for negative trend
#     *0  for no trend OR no drought events  !!!!!!
#---------------------------------------------------------------

#Load library and Functions:
#--------------------------
library(raster)
library(gdata)    # for getYears()
# # librerie per lo sviluppo grafico
library(ggplot2)     # per i grafici avanzati/mappe
library(latticeExtra) # visualizzazione di mappe spaziali di dati raster
library(rasterVis) # trasforma i Raster Object in formato leggile per ggplot2
# library(reshape2)
source("TrendFunctions.R")
#---------------


#Set data and stuff:
#------------------------------------------------
Tbegin<-as.Date(strptime("1901-01-16",format="%Y-%m-%d"))
Tend<-as.Date(strptime("2015-12-16",format="%Y-%m-%d"))
Tseries<-seq.Date(Tbegin,Tend,by="month")


#SPI time scale:
scaleSPI<-c()

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
world.map <- readShapeSpatial("Dati/TM_WORLD_BORDERS_SIMPL-0.3.shp")
world.map2 <- readShapeLines("Dati/TM_WORLD_BORDERS_SIMPL-0.3.shp")
class(world.map2)
proj4string(world.map2)<-"+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
#head(world.map@data)
require(maps)
#Per aggiungere la mappa WORLD sui grafici:
world.map <- maps::map("world")
world.map.shp <-maptools::map2SpatialLines(world.map)#, proj4string=projection(precsat.raster))
world<-maps::map("world",fill=TRUE,col="transparent", plot=F)
p4s<-CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
#SLworld<-map2SpatialLines(world,proj4string=p4s)     # se voglio LINEE con il dettaglio delle PROVINCE
countries<-world$names
SPworld<-map2SpatialPolygons(world,IDs=countries,proj4string=p4s)
#------------------------------------------------


#------------------------------------------------
#Read data  (period gen1901-dec2015: 1380 months):
#------------------------------------------------

DataList<-list.files(paste(getwd(),"/Outputs/SPI/IndexTimeSeries",sep=""),pattern = "Pearson")
for(i in 1:length(DataList)){
  
  N.ts=12; monthSPI<-month.name
  if(grepl("12",DataList[i])==TRUE){scaleSPI=12}
  if(grepl("3",DataList[i])==TRUE){scaleSPI=3}
  if(grepl("4",DataList[i])==TRUE){scaleSPI=4}
  if(grepl("6",DataList[i])==TRUE){scaleSPI=6}
  
  datax<-brick(paste(getwd(),"/Outputs/SPI/IndexTimeSeries/",DataList[i],sep=""))
  datax<-setZ(datax,Tseries)
  names(datax)<-paste("X",Tseries,sep="")

  for (m in 1:N.ts) {
    #months selection in time series:
    begin<-(match(monthSPI[m],month.name)+12)
    single_seq<-seq(begin,dim(datax)[3],by=12)
    #-----
    
    #season selection:
    datax1<-datax[[single_seq]]
    datax1<-setZ(datax1,as.Date(substr(names(datax1),2,10),format = "%Y.%m.%d"))
    # (Nyears=dim(datax1)[3])
    # plot(datax1,1:4)

    
    #Cycling on drought classes:
    for (cl in 1:length(drought.classes)) {
      ClassName<-substr(names(drought.classes[cl]),1,(nchar(names(drought.classes[cl]))-1))
      
      # Counting events by means of plugged in function:
      EventsNum<-TrendSPI_Raster(x=datax1,filename=paste("Outputs/SPI/EventsNumber/CRU_EventsNumber_",monthSPI[m],"_SPI-Pearson-",scaleSPI,"_DroughtClass_",ClassName,".nc",sep = ""),
                              threshold=drought.classes[[cl]],xSum=TRUE, monthSPI=monthSPI[m])
      #-----------------------------------------------------------
      #Maps (number of events)::
      #-----------------------------------------------------------
      #Set palette for events counting:
      colori<-colorRampPalette(c("lightgreen","yellow","orange","red"))(20)
      #my.at=c(0,1,5,10,15,20,25,max(getValues(EventsNum),na.rm = T))
      #myColorkey <- list(at=my.at, ## where the colors change
      #                   labels=list(at=c(0,1,5,10,15,20,25,max(getValues(EventsNum),na.rm = T)) )) ## where to print labels
      
      #Trellis:
      p<-levelplot(EventsNum,
                   layer=1,
                   main=list(paste("Cumulated events in ",ClassName," class, ",monthSPI[m]," SPI-",scaleSPI, " months (",
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
      
      trellis.device(png,file=paste("Plots/SPI/EventsNumber/SPI-",scaleSPI,"/CRU_EventsNumber_",monthSPI[m],"_SPI-Pearson-",scaleSPI,"_DroughtClass_",ClassName,".png",sep = ""))
      print(p)
      dev.off()
      #------
      
      # Testing trend by means of plugged in function:
      #----------------------------------------------
      # Looping alpha level for test
      for(a in 1:2){
        TrendTest<-TrendSPI_Raster(x=datax1,filename=paste("Outputs/SPI/TrendTest/CRU_TrendTest_alpha",alpha[a],"_",monthSPI[m],"_SPI-Pearson-",scaleSPI,"_DroughtClass_",ClassName,".nc",sep = ""),
                                alpha=alpha[a],threshold=drought.classes[[cl]],xSum=FALSE, monthSPI=monthSPI[m])
        
        #Maps (time-trend)::
        #Trellis
        colori<-colorRampPalette(c("green","lightgrey","red"))
        my.at=c(-1,-0.35,0.35,1)
        myColorkey <- list(at=my.at, ## where the colors change
                           labels=list(at=c(-0.70,0,0.70),labels=c("neg","no sign","pos"))) ## where to print labels
        
        p<-levelplot(TrendTest,
                     layer=1,
                     main=list(paste("Trend of events in ",ClassName," class, ",monthSPI[m]," SPI-Pearson-",scaleSPI, " months (",
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
        
        trellis.device(png,file=paste("Plots/SPI/TrendTest/SPI-",scaleSPI,"/CRU_TrendTest_alpha",alpha,"_",monthSPI[m],"_SPI-",scaleSPI,"_DroughtClass_",ClassName,".png",sep = ""))
        print(p)
        dev.off()
        #------
      } #closing "a" in alpha levels
      
    } #closing "cl" in drought.classes
  } #closing "m" in monthsSPI
} #closing "i" in DataList




  
