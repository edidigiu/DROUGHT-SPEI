#!/bin/sh


FILEOUT1="Outputs/SPEI/IndexTimeSeries/SPEI_3_CRU.nc"
FILEOUT2="Outputs/SPI/IndexTimeSeries/SPI_3_CRU_Gamma.nc"


#####  Generate files by means of Grads   ####################
# Based on files generated from CRU_?_TrendAnalysis.R:
# CRU_TrendTest_alpha0.05_August_SPI-?_DroughtClass_Severe.nc
# 1) select files from Scale="3,6,12"
# 3) select drought class  "Drought Extreme Severe+Extreme"
# 3) create png plot
##############################################################
## select drought index
if [ -e "$FILEOUT2" ] && [ -e "$FILEOUT1" ]
then
  for index in SPI SPEI
  do
    ## select SPI/SPEI time scale:
    for var in 3 4 6 12
    do
      ## select SPI/SPEI month:
      for month in  January February March April May June July August September October November December
      do
        for class in Drought 
#Extreme Severe+Extreme
        do
	   for risk in 0.05 0.1	
           do
		if [ "$index" = "SPI" ]
        	then		
			FileName=CRU_TrendTest_alpha"$risk"_"$month"_"$index"-Pearson-"$var"_DroughtClass_"$class"
        		radicein=Outputs/"$index"/TrendTest
        		radiceout=Plots/"$index"/TrendTest/"$index"-"$var"/
			
		else
			FileName=CRU_TrendTest_alpha"$risk"_"$month"_"$index"-"$var"_DroughtClass_"$class"
        		radicein=Outputs/"$index"/TrendTest
        		radiceout=Plots/"$index"/TrendTest/"$index"-"$var"/
		fi
		grads -blc "run ./Plots.EMS2016.gs $FileName $radicein $radiceout"
	   done
        done
      done
    done
  done
fi

