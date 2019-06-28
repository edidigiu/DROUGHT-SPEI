#!/bin/sh

###  LAUNCH R SCRIPT FOR GENERATING PLOTS   ###


## Declare variables ##
#---------------------#
cd ./Dati
export LastCRU=$(ls -t *pre.dat.nc | head -n 1)
cd ../
echo "Most recent CRU precipitation file is: $LastCRU"

# Extract number of CRU version:
export VerCRU=${LastCRU:6:4}
echo "CRU Version is $VerCRU"


# Loop for the two types of indexes:
for index in SPEI SPI
do
  DIRECTORY="Outputs/$index/TrendTest/$VerCRU/$index-12"
  echo "The directory of trend test results is  $DIRECTORY"
  
  # directory in Plots/:
  DIRECTORY3="Plots/$index/Plots4Paper/$VerCRU"
  echo "The new directory of the trend test plots is $DIRECTORY3"
  #----------------------#

  # Check if SPEI/SPI has been already computed.
  #---------------
  if [ $index = "SPEI" ]
  then
      FILEOUT1="Outputs/$index/TrendTest/$VerCRU/$index-12/CRU_TrendTest_alpha_0.05_September_SPEI_12_DroughtClass_Severe+Extreme.nc"
      echo "$FILEOUT1" 
  else
      FILEOUT1="Outputs/$index/TrendTest/$VerCRU/$index-12/CRU_TrendTest_alpha_0.05_September_SPI_Pearson_12_DroughtClass_Severe+Extreme.nc"
      echo "$FILEOUT1" 
  fi
  #--------------

  
  # Check if indexes have been already computed, that is "Is $DIRECTORY0 empty?":
  if [ ! -f "$FILEOUT1" ]
  then
      echo "WARNING: the $index files need to be generated first"
  else    
      echo "Since  $index trend analysis has been already computed, the script for plots generation is now launched"
      # Check if directories for SPEI/SPI trend analysis exist:
      if [ -d "$DIRECTORY" ]
      then
          echo "$DIRECTORY already exist"
          # Is $DIRECTORY empty?
          if [ "$(ls -A $DIRECTORY)" ]
          then
              echo "$index trend analysis has been already computed"
          else
              echo "B) passing $VerCRU, and $index variables to R and launching R script to generate files of plots:"
              Rscript ./Plots4Paper.R "$index" "$VerCRU" --save
          fi
      else
          echo "make directories:"
          mkdir -p "$DIRECTORY" "$DIRECTORY3" 

	        echo "A) passing $VerCRU, and $index variables to R and launching R script to generate files of $index _TrendTest*.nc time series:"
	        Rscript ./Plots4Paper.R "$index" "$VerCRU" --save
	    fi
  fi

done










