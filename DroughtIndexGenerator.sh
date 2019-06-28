#!/bin/sh

## Declare variables ##
#---------------------#
cd ./Dati
export LastCRU=$(ls -t *pre.dat.nc | head -n 1)
export LastCRU2=$(ls -t *pet.dat.nc | head -n 1)
cd ../

echo "Most recent CRU precipitation file is: $LastCRU"
echo "Most recent CRU potential evapotranspiration file is: $LastCRU2"

# Extract number of CRU version:
export VerCRU=${LastCRU:6:4}
echo "CRU Version is $VerCRU"

# Extract Time Window from CRU file name:
export TimeWin=${LastCRU:11:9}
echo "CRU Data Time Window is $TimeWin"

# Set the name of file to be built by the child below: 
export FILEOUT="Dati/cru_ts"$VerCRU"."$TimeWin".pre.dat_DryMasked.nc"
#---------------------------

## Execute DryMask.sh for checking the last downloaded dataset from CRU and applying the dry mask ##
#--------------------------------------------------------------------------------------------------#
bash ./DryMask.sh
#-----------------




##  Generate SPI and SPEI worldwide time series   ##
#--------------------------------------------------#
# Use $FILEOUT variable generated from the DryMask.sh child, that is the dry masked file
# FILEOUT="Dati/cru_ts"$VerCRU"."$TimeWin".pre.dat_DryMasked.nc"

# Check if directory of last CRU dataset version exists:
echo $VerCRU
DIRECTORY="Outputs/SPEI/IndexTimeSeries/"$VerCRU
echo "The new directory is " $DIRECTORY

if [ -d "$DIRECTORY" ]
then
	echo "$DIRECTORY already exist"
        # Is $DIRECTORY empty?
        if [ "$(ls -A $DIRECTORY)" ] 
        then
              echo "SPEI is already computed"
        else
              echo "passing $FILEOUT, $VerCRU, and $LastCRU2 variables to R and launching R script to generate files of SPEI*.nc time series:"
              Rscript ./CRU_SPEI_calculation.R "$FILEOUT" "$LastCRU2" "$VerCRU" --save
         fi      
else
        echo "make directory:"
        mkdir "$DIRECTORY"

	echo "passing $FILEOUT, $VerCRU, and $LastCRU2 variables to R and launching R script to generate files of SPEI*.nc time series:"
	Rscript ./CRU_SPEI_calculation.R $FILEOUT $LastCRU2 $VerCRU --save

fi


#####################  SPI  computation
DIRECTORY2="Outputs/SPI/IndexTimeSeries/"$VerCRU
echo "The new directory is $DIRECTORY2"

if [ -d "$DIRECTORY2" ]
then
	echo "$DIRECTORY2 already exist"
        # Is $DIRECTORY empty?
        if [ "$(ls -A $DIRECTORY2)" ] 
        then
               echo "SPI is already computed"
        else
               echo "passing $FILEOUT, $VerCRU variables to R and launching R script to generate files of SPI*.nc time series:"
	       Rscript ./CRU_SPI_calculation.R "$FILEOUT" "$VerCRU" --save

       fi

else
        echo "make directory:"
        mkdir "$DIRECTORY2"

	echo "passing $FILEOUT, $VerCRU  variables to R and launching R script to generate files of SPI*.nc time series:"
	Rscript ./CRU_SPI_calculation.R $FILEOUT $VerCRU --save

fi

rm -f  Outputs/Appo.nc

exit 0



