#! /bin/bash
#. /home/ibimet/.bashrc

########  Initialize the computation of SPI and SPEI after updating the CRU dataset version

####### Apply Dry Mask  ########
##----------------------------##
# Set to NA the whole values of time series where yearly average precipitation is lesser than 73 mm (0.2mm per day*365 days)
####  Use "cdo" tools   #####

if [ -e "$FILEOUT" ]
then
        echo "la dry mask è stata già applicata"
else
	# Extract precipitation from the dataset that is composed of pre & stn and generate the new file: pre-1.nc 
	cdo selname,pre ./Dati/"$LastCRU" ./Dati/pre-1.nc
        
	#compute the average of yearly precipitation sum:
        cdo gtc,73 -timmean -yearsum ./Dati/pre-1.nc ./Dati/cru_drymask.nc

	# apply mask to original data: 
        cdo  ifthen ./Dati/cru_drymask.nc ./Dati/"$LastCRU"  ./Dati/cru_ts"$VerCRU"."$TimeWin".pre.dat_DryMasked.nc
fi

rm -f Dati/cru_drymask.nc
rm -f Dati/pre-1.nc



