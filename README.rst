How to evaluate the trend of SPEI index in the specific drought risk classes?
=============================================================================

We present the code used for the computation of SPEI time series at a
global scale as well as that for the trend analysis. The part of code
regarding the SPEI computation starts from that proposed by (Beguería et
al. 2014) and it is based similarly on the precipitation and
evapotranspiration time series of the CRU dataset (Harris et al. 2014).
It differs from that released by (Beguería 2017): 1) because it is based
on the *raster* (Hijmans 2018) instead of *ncdf4* R package, and 2) it
is possible to set the time window for the reference period to be used
in the parameter estimation phase. The SPEI dataset resulting from our
computation is comparable in principle with the SPEI global database
released by (Beguería et al. 2014), however the comparison is not
feasible since the code released by these authors does not allow to set
reference period and, moreover it seems to contain a bug in the part
regarding the expansion of potential evapotranspiration from the
**mm/day** scale to **mm/month**.

The trend test for the different classes of drought risk is based on the
Poisson process. In fact, when a truncation level is imposed, time
series of climatological extreme phenomena become counting processes.
Generally, the arrival rate of events of a counting process follows a
Poisson distribution and, furthermore, if the arrival rate do not remain
constant through time, then it follows a nonhomogeneous Poisson process
(Nhpp). We consider the use of a special case of Nhpp's: the power law
process defined in (Crow 1974). The power law approach suggests the use
of the (:raw-latex:`\chi`^2) test for time-trend analysis.

WARNING: if using an UBUNTU machine, one should follow those steps:
-------------------------------------------------------------------

1) inserire ./ nel PATH
2) aggiungere il comando "bash", che chiama la shell corrispondente,
   prima del nome del file eseguibile; e.g. "nohup bash
   DroughtIndexGenerator.sh &"

--------------

Sequence of scripts to be launched:
-----------------------------------

1) DroughtIndexGenerator.sh (parent)

   -  cerca l'ultimo file CRU scaricato poi lancia i sottostanti
      DryMask.sh e sources .R per calcolare SPI-SPEI
   -  contiene le variabil dichiarate che vengono passate al child

1a) DryMask.sh (child) - Set to NA the whole values of time series where
yearly average precipitation is lesser than 73 mm (0.2mm per day by 365
days) to guarantee the presence of missing values in the SPEI
computation

REFERENCES
----------

.. raw:: html

   <div id="refs" class="references">

.. raw:: html

   <div id="ref-santiago_begueria_2017_834462">

Beguería, Santiago. 2017. “Sbegueria/SPEIbase: Version 2.5.1,” July.
doi:\ `10.5281/zenodo.834462 <https://doi.org/10.5281/zenodo.834462>`__.

.. raw:: html

   </div>

.. raw:: html

   <div id="ref-begueria_standardized_2014-1">

Beguería, Santiago, Sergio M. Vicente-Serrano, Fergus Reig, and Borja
Latorre. 2014. “Standardized Precipitation Evapotranspiration Index
(SPEI) Revisited: Parameter Fitting, Evapotranspiration Models, Tools,
Datasets and Drought Monitoring.” *International Journal of Climatology*
34 (10): 3001–23.
doi:\ `10.1002/joc.3887 <https://doi.org/10.1002/joc.3887>`__.

.. raw:: html

   </div>

.. raw:: html

   <div id="ref-Crow1974a">

Crow, Larry H. 1974. “Reliability Analysis for Complex, Repairable
Systems.” In *Reliability and Biometry*, edited by F. Proschan and R. G.
Serfling, 379–410. SIAM.

.. raw:: html

   </div>

.. raw:: html

   <div id="ref-harris_updated_2014">

Harris, I., P. D. Jones, T. J. Osborn, and D. H. Lister. 2014. “Updated
High-Resolution Grids of Monthly Climatic Observations the CRU TS3.10
Dataset.” *International Journal of Climatology* 34 (3): 623–42.
doi:\ `10.1002/joc.3711 <https://doi.org/10.1002/joc.3711>`__.

.. raw:: html

   </div>

.. raw:: html

   <div id="ref-hijmans_raster_2018">

Hijmans, Robert J. 2018. *Raster: Geographic Data Analysis and
Modeling*.

.. raw:: html

   </div>

.. raw:: html

   </div>
