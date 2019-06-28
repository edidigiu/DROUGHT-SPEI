####          FUNCTIONS HUB FOR SPEI/SPI COMPUTATION and TREND ANALYSIS   #############
#######################################################################################
# 1) Put1 to cases with drought severity and 0 otherwise (at single cell level)
# 1bis) if selected,count of 10-years ahead moving window
# 2) verifying if it's a Poisson distribution 
# 3) computing frequency of cases during the entire period
# 4) identifying trend sign and its significance
# 5) extending trend calculation to raster
# 6) maps
#---------------------------------------------------------------------

### Function for single cell    ####
# Put1 according to classes threshold-:: 
########################################
#
#   # threshold:levels for identifying drought class
#   # xSum: if TRUE return vector sum (default =FALSE)
#
# For testing:
# cl=1
# ClassName<-substr(names(drought.classes[cl]),1,(nchar(names(drought.classes[cl]))-1))
#x<-getValues(datax1)[2,]  #solo NA
# x<-getValues(datax1)[31816,]  
# threshold=drought.classes[[cl]]
#------------

Put1_SingleCell<-function(x,threshold,xSum=FALSE){
  x0<-numeric(length = length(x))
  x00<-na.exclude(x)
  if(any(x00 <= (-1))){
    x0[x<=threshold[2] & x>threshold[1]] <- 1
    x<-x0
  }else{
    x<-rep(NA,length.out = length(x))
  }
  ifelse(xSum==FALSE,return(x),return(sum(x)))
}
#(SingleCell<-Put1_SingleCell(x,threshold = threshold,xSum = FALSE))
#----------------------------------------------



##Test for Poisson distribution:
#(mu=sum(SingleCell))      #expected number of events in 35 years
#(lambda=mean(SingleCell))
##(expec=dpois(0:1,lambda=mean(SingleCell))*length(SingleCell))

# (Var=var(SingleCell))
# (R=Var/lambda)   #ratio
#(poisTest<-poisson.test(x=sum(SingleCell),T=length(SingleCell)))
#--------------------------------


### Power Law and Chisquare test
#plot.ecdf(SingleCell,do.points=FALSE,xval=1:length(SingleCell))
#plot(cumsum(SingleCell),type="l",xlab="Years",ylab=paste("cumulated number of ",ClassName,"events"))


### FUNCTION TO EVALUATE SPEI TREND - NHPP+Power Law ###
##   --from volcanoes notation--
# x<-getValues(datax1)[31816,]  
# x<-getValues(datax1)[2,]  # NA only
#   # x is a vector
#   # alpha: test acceptance level-- 0.05, 010 -- (default=0.05)
#   # threshold: levels for identifying drought class
#   # xSum: if TRUE return vector sum otherwise perform time trend test (default =FALSE)
trendSPEI<-function(x,alpha=0.05,threshold,xSum = FALSE){
  if(xSum==TRUE){
    x<-Put1_SingleCell(x,threshold = threshold,xSum = TRUE)
    return(x)
  }else{
    # Mann-Kendall trend test with Von Storch 1995 modification for autocorrelation (MK)
    # Mann-Kendall trend test without modification for autocorrelation (MK_easy)
    # (with the Sen'slope for the sign of the trend):
    if(length(x[is.na(x)])==length(x)){      # cells where only missings are present
      TestResultMK<-NA; MKminusNHPP<-NA; TestResultMK_classic<-NA 
    }else{
      #M-K VonStorch 1995
      MK<-pwmk(as.numeric(x))
      MK_pvalue<- round(as.numeric(MK["P-value"]),3) # Test P-Value
      Sen_slope<- round(as.numeric(MK["Sen's Slope"]),2)   #Sen's slope
      if(MK_pvalue <= alpha){
        TestMK<-"Reject H0: significative trend"
        if(Sen_slope>0) TestResultMK=1
        if(Sen_slope<0) TestResultMK=(-1)
        if(Sen_slope==0) TestResultMK=0
      }else{
        TestMK<-"Accept H0: no trend";TestResultMK<-0
      }
      suppressWarnings(warning("pwmk"))
      #M-K classic
      MK_classic<-mkttest(as.numeric(x))
      MK_pvalue_classic<-round(as.numeric(MK_classic["P-value"]),3)  # Test P-Value
      Sen_slope_classic<- round(as.numeric(MK_classic["Sen's slope"]),2)    #Sen's slope before pre-whitening
      if(MK_pvalue_classic <= alpha){
        TestMK_classic<-"Reject H0: significative trend"
        if(Sen_slope_classic>0) TestResultMK_classic=1
        if(Sen_slope_classic<0) TestResultMK_classic=(-1)
        if(Sen_slope_classic==0) TestResultMK_classic=0
      }else{
        TestMK_classic<-"Accept H0: no trend";TestResultMK_classic<-0
      }
      suppressWarnings(warning("mkttest"))
    }  
    #-------------
    
    #  Nhpp + Power Law trend test
    x<-Put1_SingleCell(x,threshold = threshold,xSum = FALSE)
    if(length(x[is.na(x)])!=0){               #==length(x)){
      TestResult<-NA
    }else{
      #no drought events, i.e. sequence of zero's:
      if(length(x[x==0])==length(x)){
        TestResult<-0
      }else{
        n=sum(x)
        t=length(x)
        S=0
        t_i<-which(x>0)
        for (i in 1:n) {S=S+log(t/t_i[i])}
        #parameter estimates:
        Beta_hat=n/S
        lambda_hat=n*Beta_hat/t   #(no. of droughts/year)
        #---
        #Chisquare test:
        Statistic=2*S
        LowerTail=qchisq(alpha/2, 2*n, ncp = 0, lower.tail = TRUE, log.p = FALSE)
        UpperTail=qchisq(alpha/2, 2*n, ncp = 0, lower.tail = FALSE, log.p = FALSE)
        if(Statistic > LowerTail & Statistic <= UpperTail) Test<-"Accept H0: no trend";TestResult<-0
        if(Statistic <= LowerTail | Statistic > UpperTail) {
          Test<-"Reject H0: significative trend"
          if(round(Beta_hat,2)>1) TestResult=1
          if(round(Beta_hat,2)<1) TestResult=(-1)
          if(round(Beta_hat,2)==1) TestResult=0
        }  
      }
    }
    # Subtraction of MK minus NHPP:
    MKminusNHPP <- TestResult - TestResultMK  
    return(c(TestResult,TestResultMK,TestResultMK_classic,MKminusNHPP))
  } # close first if
}   # close function()

#(TrendTest<-trendSPEI(x,alpha=0.05,threshold=drought.classes[[5]],xSum = FALSE))
#-------------------------



####   FUNCTION FOR RASTER   #####
# "x" is a RasterStack or RasterBrick  
# "filename" is output filename
# "threshold" vector of 2 elements to delimit a bin for the events
# "xSum" TRUE to count the events in each bin, FALSE to perform trend test (default=F)
# "monthSPEI" character, month name (not abbreviation) of SPEI calculation
# x<-crop(datax1,extent(c(-12.3,61.6,-46.5,58.8)))

# Building a raster object of 4 layers (1 for NHPP,1 for M-K with autocorrelation modification,1 for M-K traditional, 1 for their difference)   #####
TrendSPEI_Raster<-function(x,filename,alpha=0.05,threshold,month,xSum=FALSE){  
  
  month_lab<-c("01","02","03","04","05","06","07","08","09","10","11","12")
  
  # Computing by Multi-cores
  require(parallel)
  numCores <- detectCores()
  numCores <- trunc((numCores / 2)+1)
  
  #  if(xSum=T) that is compute the numer of events in each class instead of trend test --------
  #-------------------------
  if(xSum==T) {
    out<-raster(x) # empty raster with spatial dimension of x 
    
    # Computing by blocks
    bs <- blockSize(out)
    pb <- pbCreate(bs$n, progress="text")  # progress bar
    
    out <- writeStart(out, filename,
                      format="CDF",overwrite=TRUE, varname="N_events",varunit="FLOAT",
                      longname="counting of events in each class", xname="lon", yname="lat",zname="time",zunit=paste("months since 2000-",month_lab[m],"-16",sep="")
                      )
    
    for (i in 1:bs$n) {  
      v <- getValuesBlock(x, row=bs$row[i], nrows=bs$nrows[i] )
      
      # from matrix to list:
      v_list <- lapply(seq_len(nrow(v)), function(j) v[j,])
      # Parallelized computation on list
      v_counts <- mclapply(v_list,FUN=trendSPEI,threshold=threshold,xSum=xSum, mc.cores = numCores)
      
      # Back to matrix
      v_counts_m <- matrix(unlist(v_counts,use.names = FALSE),nrow=bs$nrows,ncol=dim(out)[2], byrow=FALSE)     
      
      out <- writeValues(out, v_counts_m, bs$row[i])
      pbStep(pb, i)
    }  #close loop "i" over blocks
  out <- writeStop(out)  
  rm(v_list,v_counts,v_counts_m)
  }  #close if 
  #---------------
  
  #  Trend test computation
  #------------------------
  if(xSum==F) {
  
    out<-brick(raster(x),nl=4) # empty raster with spatial dimension of x and 3 layers (1 for NHPP,1 for M-K, 1 for their difference)
    names(out)<-c("Nhpp","MK","MK-classic","Diff")
    
    # Computing by blocks
    bs <- blockSize(out)
    pb <- pbCreate(bs$n, progress="text")  # progress bar
  
    out <- writeStart(out, filename,
                    format="CDF",overwrite=TRUE, varname="trend",varunit="FLOAT",  
                    longname="Trend Analysis of SPEI",xname="lon", yname="lat",zname="time",zunit=paste("years since 2000-",month_lab[m],"-16",sep="")
                    )   
  
    for (i in 1:bs$n) { 
      u<-matrix(nrow=(bs$nrows[i]*(dim(out)[2])),ncol=nlayers(out))  # storage of test results
      v <- getValuesBlock(x, row=bs$row[i], nrows=bs$nrows[i] )
    
      # from matrix to list:
      v_list <- lapply(seq_len(nrow(v)), function(j) v[j,])
      # Parallelized computation on list
      v_test <- mclapply(v_list,FUN=trendSPEI,alpha=alpha,threshold=threshold,xSum=xSum, mc.cores = numCores)
      
      # Back to matrix
      u[] <- matrix(unlist(v_test,use.names = FALSE),nrow=nrow(u),byrow = TRUE)  
      
      out <- writeValues(out, u, bs$row[i])
      pbStep(pb, i)
    }  #close loop "i" over blocks
  out <- writeStop(out)
  rm(v_list,v_test)
  }  #close if 
  #---------------
return(out)  
}

# # Debugging
# appo<-matrix(nrow=(bs$nrows[i]*(dim(out)[2])),ncol=nlayers(out))
# for(p in 1:length(v_list)){
#   x<-v_list[[p]]
#   appo[p,]<-trendSPEI(x,alpha=0.05,threshold=drought.classes[[5]],xSum = FALSE)
# }

#-----------------------



#tutti1<-TrendSPEI_Raster(x,filename="prova.nc",alpha=0.05,threshold=drought.classes[[cl]],month=5,xSum = FALSE)
#----------------------------------------------------------------------



### FUNCTION TO EVALUATE SPI TREND ###
##   --from volcanoes notation--
# x<-getValues(datax1)[318160,]  
# x<-getValues(datax1)[2,]  #solo NA
#   # x is raster
#   # alpha: test acceptance level-- 0.05, 010, etc.  -- (default=0.05)
#   # threshold: levels for identifying drought class
#   # xSum: if TRUE return vector sum otherwise perform time trend test (default =FALSE)
trendSPI<-function(x,alpha=0.05,threshold,xSum = FALSE){
  if(xSum==TRUE){
    x<-Put1_SingleCell(x,threshold = threshold,xSum = TRUE)
    return(x)
  }else{
    x<-Put1_SingleCell(x,threshold = threshold,xSum = FALSE)
    if(length(x[is.na(x)])!=0){#==length(x)){
      TestResult<-NA
    }else{
      #no drought events, i.e. sequence of zero's:
      if(length(x[x==0])==length(x)){
        TestResult<-0
      }else{
        n=sum(x)
        t=length(x)
        S=0
        t_i<-which(x>0)
        for (i in 1:n) {S=S+log(t/t_i[i])}
        #parameter estimates:
        Beta_hat=n/S
        lambda_hat=n*Beta_hat/t   #(no. of droughts/year)
        #---
        #Chisquare test:
        Statistic=2*S
        LowerTail=qchisq(alpha/2, 2*n, ncp = 0, lower.tail = TRUE, log.p = FALSE)
        UpperTail=qchisq(alpha/2, 2*n, ncp = 0, lower.tail = FALSE, log.p = FALSE)
        if(Statistic > LowerTail & Statistic <= UpperTail) Test<-"Accept H0: no trend";TestResult<-0
        if(Statistic <= LowerTail | Statistic > UpperTail) {
          Test<-"Reject H0: significative trend"
          if(Beta_hat>1) TestResult=1
          if(Beta_hat<1) TestResult=(-1)
        }  
      }
    }
    return(TestResult)
  }
}

#(TrendTest<-trendSPI(x,alpha=0.05,threshold=threshold,xSum = FALSE))

####   FUNCTION FOR RASTER   #####
# "x" is a RasterStack or RasterBrick  
# "filename" is output filename
# "threshold" vector of 2 elements to delimit a bin for the events
# "xSum" TRUE to count the events in each bin, FALSE to perform trend test (default=F)
# "monthSPI" character, month name (not abbreviation) of SPI calculation
#x<-crop(datax1,extent(c(11.3,12.6,41.5,43.8)))
TrendSPI_Raster<-function(x,filename,alpha=0.05,threshold,xSum=FALSE,monthSPI){  
  #out<-brick(x,values=F) #contenitore rasterBrick vuoto con le stesse caratteristiche di x
  out<-raster(x) #contenitore raster vuoto con le stesse caratteristiche di x
  
  out <- writeStart(out, filename, format="CDF",overwrite=TRUE)#,zname="time",zunit="months")    
  for (i in 1:nrow(out)) {   
    v <- getValues(x, i)
    v <- t(apply(v,MARGIN=1,FUN=trendSPI,alpha=alpha,threshold=threshold,xSum=xSum))  
    out <- writeValues(out,v , i) 
  }  #chiudo ciclo "i" sulle rows del raster x
  
  out <- writeStop(out)
  names(out)<-monthSPI
  return(out)  
}

# tutti1<-Trend_Raster(x,filename="prova.nc",alpha=0.05,threshold=drought.classes[[cl]],xSum = FALSE,
#                      monthSPI = monthSPI[m])
#----------------------------------------------------------------------


#####################################################
######   FUNCTION HUB for CRU  ######################
#::::::::::::::::::::::::::::::::::::::::::::::::::::
#### Function for 30-years monthly average:
#------------------------------------------
ClinoMensili<-function(db.raster,fun){  #db.raster=db su cui calcolare le medie; #funzione=c(media,mediana)   
  FUN<-match.fun(fun)
  clino.12mesi<-raster(db.raster)
  for (m in 1:12){
    mese.tutti<-subset(db.raster,seq(m,dim(db.raster)[3],by=12))
    clino.mese<-round(calc(mese.tutti,FUN),1)
    clino.12mesi<-addLayer(clino.12mesi,clino.mese)
  }
  names(clino.12mesi)<-month.abb
  return(clino.12mesi)
}
#-----------------------------------------


##  SPEI COMPUTATION  #####
#x<-crop(precCRU,extent(c(11.0,14.5,41.5,44.5)))
#x<-crop(precCRUmed,extent(c(11.5,12.0,41.5,42.0)))   ### solo NA
#x<-getValues(x)[1,]
## Internal function for extracting fitted values from SPEI() function in SPEI package::
#  x is the climatic balance precipitation minus potential evapotranspiration
#   -- set reference period for estimation phase to 1971-2000 ---
SPEI.fitted<-function(x,ts.start,scale,na.rm,ref.start,ref.end){
  #transform into ts object:
  x<-ts(as.vector(x),start = ts.start,frequency = 12)   # build ts object in order to use ref.start(ref.end)
  y<-spei(x,scale=scale,na.rm=na.rm,ref.start=ref.start,ref.end=ref.end)$fitted
  y[is.infinite(y)] <- NA    # from infinite values to NA
  y<-as.vector(y)   #back to vector format
  return(y)
}

#SPEI.fitted(x,ts.start = ts.start,scale = 3,na.rm=T,ref.start = c(1971,1),ref.end = c(2000,12))


# # Extract coefficients:
# SPEI.coefficients<-function(x,ts.start,scale,na.rm,ref.start,ref.end){
#   #transform into ts object:
#   x<-ts(x,start = ts.start,frequency = 12)
#   y<-spei(x,scale=scale,na.rm=na.rm,ref.start=ref.start,ref.end=ref.end)$coefficients
#   return(y)
# }


####  SPEI APPLIED OVER RASTER  ######
#  #ts.start=c(year,month)   initialize time series
#  #scale=1,3,6,12,48 for SPEI() 
# X.times= sequence of dates to set in NetCDF
#  #ref.start=c(year,month)  subsetting 30-years period for estimating Gamma parameters:
SPEI_Raster<-function(x,filename,ts.start,scale,na.rm,ref.start,ref.end){  
  out<-brick(x,values=F) #empty rasterBrick dimensioned as x
  
  
  # Computing by Multi-cores
  require(parallel)
  numCores <- detectCores()
  numCores <- trunc((numCores / 2)+1)
  
  # mclapply directly sets up a pool of mc.cores workers just for  this  computation
  
  #       HOWEVER
  
  # For matrices there is the more commonly used parRapply(), a parallel row apply for a matrix.
  # to use parLapply the call to makeCluster() is needed
  # cl <- makeCluster(numCores)
  # parRapply(...)
  # stopCluster(cl)
  # 
  
  # Computing by blocks
  bs <- blockSize(out)
  pb <- pbCreate(bs$n, progress="text")  # progress bar
  
  out <- writeStart(out, filename,
                    format="CDF",overwrite=TRUE, varname="spei", #varunit="z-scores", 
                    longname="Standardized Precipitation-Evapotranspiration Index", xname="lon", yname="lat",zname="time",
                    zunit="months since 1900-12-16")    
  for (i in 1:bs$n) {  
    v <- getValues(x, row=bs$row[i], nrows=bs$nrows[i] )
    
    # from matrix to list:
    v <- lapply(seq_len(nrow(v)), function(i) v[i,])
    # Parallelized computation on list
    v <- mclapply(v,FUN=SPEI.fitted,scale=scale,na.rm=na.rm,
                 ts.start=ts.start,ref.start=ref.start,ref.end=ref.end, mc.cores = numCores)
    # Back to matrix
    v <- matrix(unlist(v,use.names = FALSE),ncol=dim(out)[3],byrow=TRUE)
    
    out <- writeValues(out, v, bs$row[i])
    pbStep(pb, i)
  }  #close loop "i" over blocks
  
  out <- writeStop(out)
  
  pbClose(pb)
  return(out)  
}

# ### DA AGGIUSTARE IL NUMERO DI ELEMENTI IN USCITA:!!!!
# # Extract coefficients used for SPEI calculation:
# SPEI_Raster_coefficients<-function(x,filename,ts.start,scale,na.rm,ref.start,ref.end){  
#   out<-brick(x,values=F) #contenitore rasterBrick vuoto con le stesse caratteristiche di x
#   #out<-raster(x) #contenitore raster vuoto con le stesse caratteristiche di x
#   
#   out <- writeStart(out, filename, format="CDF",overwrite=TRUE)#,zname="time",zunit="months")    
#   for (i in 1:nrow(out)) {   
#     v <- getValues(x, i)
#     v <- t(apply(v,MARGIN=1,FUN=SPEI.coefficients,scale=scale,na.rm=na.rm,
#                  ts.start=ts.start,ref.start=ref.start,ref.end=ref.end))  
#     out <- writeValues(out,v , i) 
#   }  #chiudo ciclo "i" sulle rows del raster x
#   
#   out <- writeStop(out)
#   #names(out)<-monthSPEI
#   return(out)  
# }

#::::::::::::::::::::::::::::::::::::::::::::::::::



##  SPI COMPUTATION  #####
#x<-crop(precCRUmed,extent(c(11.0,14.5,41.5,44.5)))
#x<-crop(precCRUmed,extent(c(11.5,12.0,41.5,42.0)))   ### solo NA
#x<-getValues(x)[1,]
## Internal function for extracting fitted values from spi() function in SPEI package::
#   -- set reference period for estimation phase to 1971-2000 ---
SPI.fitted<-function(x,ts.start,scale,na.rm,ref.start,ref.end,distribution){
  #transform into ts object:
  x<-ts(x,start = ts.start,frequency = 12)
  y<-spi(x,scale=scale,na.rm=na.rm,ref.start=ref.start,ref.end=ref.end,distribution = distribution)$fitted
  return(y)
}

#SPI.fitted(x,ts.start = ts.start,scale = 3,na.rm=T,ref.start = c(1971,1),ref.end = c(2000,12))


# # Extract coefficients:
# SPI.coefficients<-function(x,ts.start,scale,na.rm,ref.start,ref.end,distribution){
#   #transform into ts object:
#   x<-ts(x,start = ts.start,frequency = 12)
#   y<-spi(x,scale=scale,na.rm=na.rm,ref.start=ref.start,ref.end=ref.end,distribution = distribution)$coefficients
#   return(y)
# }



####  SPI APPLIED OVER RASTER  ######
#  #ts.start=c(year,month)   initialize time series
#  #scale=1,3,6,12,48 for spi() 
# X.times= sequence of dates to set in NetCDF
#  #ref.start=c(year,month)  subsetting 30-years period for estimating Gamma parameters:
SPI_Raster<-function(x,filename,ts.start,scale,na.rm,ref.start,ref.end,distribution,X.times=Xtimes){  
  out<-brick(x,values=F) #contenitore rasterBrick vuoto con le stesse caratteristiche di x
  
  # Computing by Multi-cores
  require(parallel)
  numCores <- detectCores()
  numCores <- trunc((numCores / 2)+1)
  
  # mclapply directly sets up a pool of mc.cores workers just for  this  computation
  
  #       HOWEVER
  
  # For matrices there is the more commonly used parRapply(), a parallel row apply for a matrix.
  # to use parLapply the call to makeCluster() is needed
  # cl <- makeCluster(numCores)
  # parRapply(...)
  # stopCluster(cl)
  # 
  
  # Computing by blocks
  bs <- blockSize(out)
  pb <- pbCreate(bs$n, progress="text")  # progress bar
  
  out <- writeStart(out, filename,
                    format="CDF",overwrite=TRUE, varname="spi", #varunit="z-scores", 
                    longname="Standardized Precipitation Index", xname="lon", yname="lat",zname="time",
                    zunit="months since 1900-12-16")    
  for (i in 1:bs$n) {  
    v <- getValues(x, row=bs$row[i], nrows=bs$nrows[i] )
    
    # from matrix to list:
    v <- lapply(seq_len(nrow(v)), function(i) v[i,])
    # Parallelized computation on list
    v <- mclapply(v,FUN=SPI.fitted,scale=scale,na.rm=na.rm,
                  ts.start=ts.start,ref.start=ref.start,ref.end=ref.end,distribution=distribution, mc.cores = numCores)
    # Back to matrix
    v <- matrix(unlist(v,use.names = FALSE),ncol=dim(out)[3],byrow=TRUE)
    
    out <- writeValues(out, v, bs$row[i])
    pbStep(pb, i)
  }  #close loop "i" over blocks
  
  out <- writeStop(out)
  
  pbClose(pb)
  return(out)  
}



#  Write file with coefficients
SPI_Raster_coefficients<-function(x,filename,ts.start,scale,na.rm,ref.start,ref.end,distribution){  
  out<-brick(x,values=F) #contenitore rasterBrick vuoto con le stesse caratteristiche di x
  #out<-raster(x) #contenitore raster vuoto con le stesse caratteristiche di x
  
  out <- writeStart(out, filename, format="CDF",overwrite=TRUE)#,zname="time",zunit="months")    
  for (i in 1:nrow(out)) {   
    v <- getValues(x, i)
    v <- t(apply(v,MARGIN=1,FUN=SPI.coefficients,scale=scale,na.rm=na.rm,
                 ts.start=ts.start,ref.start=ref.start,ref.end=ref.end,distribution=distribution))  
    out <- writeValues(out,v , i) 
  }  #chiudo ciclo "i" sulle rows del raster x
  
  out <- writeStop(out)
  #names(out)<-monthSPI
  return(out)  
}



#::::::::::::::::::::::::::::::::::::::::::::::::::




######################################################################
####   spi() and spei()  functions from  SPEI package   ##############  
######################################################################
##spei() is needed to apply spi()::

#################################################################

### OTHER ATTEMPT FUNCTIONS  ########
# ## Same function with the option of setting a moving window::
# Put1_SingleCell_MovWindow<-function(x,threshold,MovWindow){     
#   #threshold:levels for identifying drought class
#   #MovWindow: define number of years of moving window
#   x0<-numeric(length = length(x))
#   x00<-numeric(length = length(x))
#   names(x00)<-names(x)
#   x000<-na.exclude(x)
#   if(any(x000 <= (-1))){
#     x0[x<=threshold[2] & x>threshold[1]]<-1
#     for (i in MovWindow:length(x0)) {x00[i]<-sum(x0[i:(i-MovWindow)])}
#     x<-x00[MovWindow:length(x00)]
#   }else{
#     x<-rep(NA,length.out = (length(x)-MovWindow-1))
#   }
#   return(x)
# } 
# prova<-Put1_SingleCell_MovWindow(x,threshold = moderateT,MovWindow=Twindow)
# prova

#-------------------------
####  TrendSPEI_Raster()
#  TrendSPEI_Raster<-function(x,filename,alpha=0.05,threshold,xSum=FALSE,monthSPEI){  
#   #out<-brick(x,values=F) #contenitore rasterBrick vuoto con le stesse caratteristiche di x
#   out<-raster(x) #contenitore raster vuoto con le stesse caratteristiche di x
#   
#   out <- writeStart(out, filename, format="CDF",overwrite=TRUE)#,zname="time",zunit="months")    
#   for (i in 1:nrow(out)) {   
#     v <- getValues(x, i)
#     v <- t(apply(v,MARGIN=1,FUN=trendSPEI,alpha=alpha,threshold=threshold,xSum=xSum))  
#     out <- writeValues(out,v , i) 
#   }  #chiudo ciclo "i" sulle rows del raster x
#   
#   out <- writeStop(out)
#   names(out)<-monthSPEI
#   return(out)  
# }

#----------------------------------------


