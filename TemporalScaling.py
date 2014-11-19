from __future__ import division

# Read in individual and species data
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
species_data = pd.read_csv("FinalSpeciesList.csv")

# Read in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
import numpy as np
import matplotlib.pyplot as plt
import netCDF4
temperature_data = netCDF4.Dataset("air.mon.mean.v301.nc", mode="r")

# Read in temperature data variables
lat = nc.variables["lat"][:]
lon = nc. variables["lon"][:]
times = nc.variables["time"]



#jd = netCDF4.num2date(times[:],times.units)

def near(array,value):
    idx=(np.abs(array-value)).argmin()
    return idx

ix = near(lon, loni)
iy = near(lat, lati)

vname = "mer_mer_mer"
var = nc.variables[vname]
h = var[:,iy,ix]

plt.figure(figsize=(16,4))
plt.plot_date(jd,h,fmt='-')
plt.grid()
plt.ylabel(var.units)
plt.title("baa_baa_baa")
    

# Read in temperature data try 2
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
# Error 4: doesn't recognize .nc file formats
# Changed to full path name, same result
temperature_data2 = gdal.Open("air.mon.mean.v301.nc")
print temperature_data2.GetMetadata()

