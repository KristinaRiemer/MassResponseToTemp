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
originX = temperature_data_geotransform[0]    #top left x
originY = temperature_data_geotransform[3]    #top left y
pixelWidth = temperature_data_geotransform[1]    #west-east resolution
pixelHeight = temperature_data_geotransform[5]    #north-south resolution

# Specify which band, i.e., year, read in that band, and get specific value
# Not getting expected values, should be temperatures
# Choose these x and y values?
#x = 236.07
#y = 40.71
#xOffset = int((x - originX) / pixelWidth)
#yOffset = int((y - originY) / pixelHeight)

band = temperature_data.GetRasterBand(283)
bandtype = gdal.GetDataTypeName(band.DataType)
data = band.ReadAsArray(0, 0, cols, rows)
value = data[40.71, 236.07]

import matplotlib.pyplot as plt
plt.plot(data)


def get_value_at_point(rasterfile, pos):
    gdata = gdal.Open(rasterfile)
    gt = gdata.GetGeoTransform()
    data = gdata.ReadAsArray()
    gdata = None
    x = int((pos[0] - gt[0])/gt[1])
    y = int((pos[1] - gt[3])/gt[5])
    return data[y, x] 

p = (236.07, 40.71)
get_value_at_point(temperature_data, p)