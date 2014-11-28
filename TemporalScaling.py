from __future__ import division

# Read in individual and species data
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
species_data = pd.read_csv("FinalSpeciesList.csv")

# Read in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temperature_data = gdal.Open("air.mon.mean.v301.nc")

# Useful GDAL commands
#print temperature_data2.GetMetadata()
cols = temperature_data.RasterXSize
rows = temperature_data.RasterYSize
bands = temperature_data.RasterCount

# Get info about file
temperature_data_geotransform = temperature_data.GetGeoTransform()
originX = temperature_data_geotransform[0]
originY = temperature_data_geotransform[3]
pixelWidth = temperature_data_geotransform[1]
pixelHeight = temperature_data_geotransform[5]

# Specify which band, i.e., year, read in that band, and get specific value
# Not getting expected values, should be temperatures
band = temperature_data.GetRasterBand(1000)
bandtype = gdal.GetDataTypeName(band.DataType)
data = band.ReadAsArray(0, 0, cols, rows)
value = data[40, 237]
