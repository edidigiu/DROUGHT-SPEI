#!/bin/sh

## Declare variables ##
#---------------------#
cd ./Dati
export LastCRU=$(ls -t *pre.dat.nc | head -n 1)
cd ../
echo "Most recent CRU precipitation file is: $LastCRU"

# Extract number of CRU version:
export VerCRU=${LastCRU:6:4}
echo "CRU Version is $VerCRU"

#export alpha=0.05
#echo "The test level is $alpha"
#----------------------#

# Loop for the two types of indexes:
for index in SPEI SPI
do
  DIRECTORY="Outputs/$index/TrendTest/$VerCRU/$index-12"
  echo "The new directory for trend test results is  $DIRECTORY"
  DIRECTORY2="Outputs/$index/EventsNumber/$VerCRU"
  echo "The new directory for the counting of drought events is  $DIRECTORY2"
  
  # directory in Plots/:
  DIRECTORY3="Plots/$index/TrendTest/$VerCRU"
  echo "The new directory for the plots of trend test is $DIRECTORY3"
  DIRECTORY4="Plots/$index/EventsNumber/$VerCRU"
  echo "The new directory for the plots of drought counting is $DIRECTORY4"
  #----------------------#

  # Check if SPEI/SPI has been already computed.
  #---------------
  if [ $index = "SPEI" ]
  then
      FILEOUT1="Outputs/$index/IndexTimeSeries/$VerCRU/"$index"_3_CRU.nc"
      echo "$FILEOUT1" 
  else
      FILEOUT1="Outputs/$index/IndexTimeSeries/$VerCRU/"$index"_6_CRU_PearsonIII.nc"
      echo "$FILEOUT1" 
  fi
  #--------------

  
  # Check if indexes have been already computed, that is "Is $DIRECTORY0 empty?":
  if [ ! -f "$FILEOUT1" ]
  then
      echo "WARNING: the $index files need to be generated first"
  else    
      echo "Since  $index time series have been already computed, the script for trend analysis is now launched"
      # Check if directories for SPEI/SPI trend analysis exist:
      if [ -d "$DIRECTORY" ]
      then
          echo "$DIRECTORY already exist"
          # Is $DIRECTORY empty?
          if [ "$(ls -A $DIRECTORY)" ]
          then
              echo "$index trend analysis has been already computed"
          else
              echo "B) passing $VerCRU, and $index variables to R and launching R script to generate plots:"
              Rscript ./CRU_SPEI_TrendAnalysis.R "$index" "$VerCRU"  --save
          fi
      else
          echo "make directories:"
          mkdir -p "$DIRECTORY" "$DIRECTORY2" "$DIRECTORY3" "$DIRECTORY4"

	        echo "A) passing $VerCRU, and $index variables to R and launching R script to generate plots:"
	        Rscript ./CRU_SPEI_TrendAnalysis.R "$index" "$VerCRU" --save
	    fi
  fi

done










