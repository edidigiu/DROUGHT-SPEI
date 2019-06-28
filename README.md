# How to evaluate the trend of SPEI index in the specific drought risk classes?

There might be unevenness  between the use of non parametric (Mann-Kendall) and parametric approach for computing the trend of drought index values time series. The typical methodological framework to assess the SPI-SPEI time series trend in hydrology is to combine M-K (Mann-Kendall) test with UB or $\beta$-Sen.
Since thresholds are set to take into account different levels of risk, the proper method to assess such a trend should be the Poisson process.


##  WARNING:  if using an UBUNTU machine, one should follow those steps:
1) inserire ./ nel PATH
2) aggiungere il comando "bash", che chiama la shell corrispondente, prima del nome del file eseguibile;
     e.g.  "nohup bash DroughtIndexGenerator.sh &"  

--------------

## Sequence of scripts to be launched:

1) DroughtIndexGenerator.sh  (parent)  
	- cerca l'ultimo file CRU scaricato poi lancia i sottostanti DryMask.sh  e sources .R per calcolare SPI-SPEI
	- contiene le variabil dichiarate che vengono passate al child

<<<<<<< HEAD
2) DryMask.sh  (child)
	- Set to NA the whole values of time series where yearly average precipitation is lesser than 73 mm (0.2mm per day*365 days) to guarantee the presence of missing values in the SPEI computation
=======
1a) DryMask.sh  (child)
	- Set to NA the whole values of time series where yearly average precipitation is lesser than 73 mm (0.2mm per day by 365 days) to guarantee the presence of missing values in the SPEI computation

>>>>>>> bcfb25497ed0690cd0637f03705601e7a0c0a9d0

