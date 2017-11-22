[![DOI](https://zenodo.org/badge/17957630.svg)](https://zenodo.org/badge/latestdoi/17957630)

#### Purpose
To determine if there is an intraspecific relationship between mass and temperature for many animals species at broad temporal and spatial scales. This is motivated by the prediction that animal species will respond to climate change with body size shifts. 

Also of interest is if temperatures from years before individuals are collected (temporal lag; TL) are better at explaining mass variation than the temperature from the collection year (current year; CY).  

#### Datasets
* Individual mass: [Vertnet museum compilation](http://vertnet.org/), from which trait data were extracted by Rob Guralnick, et al. 
  * Initially used mass data from [Smithsonian mammal collections](http://collections.nmnh.si.edu/search/mammals/)
* Temperature: monthly mean temperature data in a raster format going back to 1900 from [NOAA/University of Delaware](http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html)

#### To run code
Using R 3.3.1 and Python 2.7.10

Install the required R packages. This can be done automatically by running:

```
Rscript install-packages.R
```

* cowplot_0.6.3
* ggplot2_2.2.1
* plyr_1.8.4
* rdataretriever_1.0.0
* dplyr_0.5.0
* spatstat_1.47-0
* taxize_0.8.4
* stringr_1.2.0
* readr_1.0.0

Install the required Python packages. This can be done automatically using
`conda` by running:

```
conda env create --file environment.yml
source activate MassResponseToTemp
```

* retriever==2.0.0
* matplotlib==1.4.3
* pandas==0.16.2
* numpy==1.9.2
* statsmodels==0.6.1
* joblib==0.9.4
* gdal==2.0.0 (with conda, not pip)

These come with Python: 
* time
* calendar

Download .zip of entire repository, then run `bash repro_run.sh` in the command line. You will need internet access to download the raw data files. 

Note: this will only provide results for a subset of the data. If you want to run for all of the data, comment out lines 9 - 11 of `repro_run.sh` and run `bash repro_run.sh`. This will take several days to complete. 
