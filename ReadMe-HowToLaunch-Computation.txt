#################################    Edmondo Di Giuseppe 28 Marzo 2019    ##################################
#  NOTA BENE
#  IN UBUNTU è NECESSARIO:
#####  1) inserire ./ nel PATH
#####  2) aggiungere il comando "bash", che chiama la shell corrispondente, prima del nome del file eseguibile;
#####     e.g.  "nohup bash DroughtIndexGenerator.sh &"  

#############################################################################################################

#
# Sequence of scripts to be launched:

1) DroughtIndexGenerator.sh  (parent)  
	# cerca l'ultimo file CRU scaricato poi lancia i sottostanti DryMask.sh  e sources .R per calcolare SPI-SPEI
	# contiene le variabil dichiarate che vengono passate al child

1a) DryMask.sh  (child)
	# Set to NA the whole values of time series where yearly average precipitation is lesser than 73 mm (0.2mm per day*365 days) to guarantee the presence of missing values in the SPEI computation



########    Separare i prossimi due in un altro file .sh
3) DroughtTrendTest-Generator.sh (needs sources .R)

4) GradsPlotsGenerator.sh  (needs source .gs)

