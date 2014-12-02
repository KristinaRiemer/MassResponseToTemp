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
temp_metadata = temperature_data.GetMetadata()
cols = temperature_data.RasterXSize
rows = temperature_data.RasterYSize
bands = temperature_data.RasterCount

# Get info about file
temperature_data_geotransform = temperature_data.GetGeoTransform()
originX = temperature_data_geotransform[0]    #top left x
originY = temperature_data_geotransform[3]    #top left y
pixelWidth = temperature_data_geotransform[1]    #west-east resolution
pixelHeight = temperature_data_geotransform[5]    #north-south resolution
#bandtype = gdal.GetDataTypeName(band.DataType)

# Specify which band, i.e., year, read in that band, and get specific value
# Not getting expected values, should be temperatures

band = temperature_data.GetRasterBand(1267)
add_offset = band.GetOffset()
scale_factor = band.GetScale()

data = band.ReadAsArray(0, 0, cols, rows)
# data[lat, lon]
value = data[30.83, 276.73]
temperature_value = add_offset + (value * scale_factor)
print temperature_value

#import matplotlib.pyplot as plt
#plt.plot(data)

import numpy as np
def get_value_at_point(rasterfile, pos):
    gdata = gdal.Open(rasterfile)    #opens raster file
    gt = gdata.GetGeoTransform()    #geotranforms raster to get gt points below
    data = gdata.ReadAsArray().astype(np.float)    #reads in all file's bands as array
    gdata = None    #closes file, considered good practice
    x = int((pos[0] - gt[0])/gt[1])    #calculates offset for x
    y = int((pos[1] - gt[3])/gt[5])    #calculates offset for y
    return data[y, x] 

p = (276.73, 30.83)
get_value_at_point("air.mon.mean.v301.nc", p)


gdata = gdal.Open("air.mon.mean.v301.nc")    #opens raster file
gt = gdata.GetGeoTransform()    #geotranforms raster to get gt points below
data = gdata.ReadAsArray().astype(np.float)    #reads in all file's bands as array
gdata = None    #closes file, considered good practice

pos = (276.73, 30.83)
x = int((pos[0] - gt[0])/gt[1])    #calculates offset for x
y = int((pos[1] - gt[3])/gt[5])    #calculates offset for y
return data[y, x] 


gdata = gdal.Open("air.mon.mean.v301.nc")    #opens raster file
band = gdata.GetRasterBand(1)    #get desired band from raster stack
gt = gdata.GetGeoTransform()    #geotranforms raster to get gt points below
#then close file?
pos = (3, -80)
x = int((pos[0] - gt[0])/gt[1])    #calculates offset for x
y = int((pos[1] - gt[3])/gt[5])    #calculates offset for y
cols = gdata.RasterXSize
rows = gdata.RasterYSize
data = band.ReadAsArray()
print data[y, x]




def GetExtent(gt,cols,rows):
    ''' Return list of corner coordinates from a geotransform

        @type gt:   C{tuple/list}
        @param gt: geotransform
        @type cols:   C{int}
        @param cols: number of columns in the dataset
        @type rows:   C{int}
        @param rows: number of rows in the dataset
        @rtype:    C{[float,...,float]}
        @return:   coordinates of each corner
    '''
    ext=[]
    xarr=[0,cols]
    yarr=[0,rows]

    for px in xarr:
        for py in yarr:
            x=gt[0]+(px*gt[1])+(py*gt[2])
            y=gt[3]+(px*gt[4])+(py*gt[5])
            ext.append([x,y])
            print x,y
        yarr.reverse()
    return ext


import netCDF4

temperature_data_look = netCDF4.Dataset("air.mon.mean.v301.nc")
