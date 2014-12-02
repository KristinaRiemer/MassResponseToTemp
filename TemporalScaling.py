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

# Function to extract temperature at specific longitude, latitude, and month
def get_value_at_point(rasterfile, pos, chosen_band):
    gdata = gdal.Open(rasterfile)    #opens raster file
    band = gdata.GetRasterBand(chosen_band)    #get desired band from raster stack
    gt = gdata.GetGeoTransform()    #geotranforms raster to get gt points below
    #gdata = None    #closes file, considered good practice, causes to abort?
    x = int((pos[0] - gt[0])/gt[1])    #calculates offset for x
    y = int((pos[1] - gt[3])/gt[5])    #calculates offset for y
    data = band.ReadAsArray()    #creates array of temperatures for specific band
    packed_value = data[y, x]    #outputs packed temp at offset from that array (short integer)
    add_offset = band.GetOffset()    #get offset to unpack
    scale_factor = band.GetScale()    #get scale factor to unpack
    unpacked_value = add_offset + (packed_value * scale_factor)
    return unpacked_value


p = (276.73, 30.83)
b = 1267
print get_value_at_point("air.mon.mean.v301.nc", p, b)
    
    



## Useful GDAL commands
#temp_metadata = temperature_data.GetMetadata()
#cols = temperature_data.RasterXSize
#rows = temperature_data.RasterYSize
#bands = temperature_data.RasterCount

## Get info about file
#temperature_data_geotransform = temperature_data.GetGeoTransform()
#originX = temperature_data_geotransform[0]    #top left x
#originY = temperature_data_geotransform[3]    #top left y
#pixelWidth = temperature_data_geotransform[1]    #west-east resolution
#pixelHeight = temperature_data_geotransform[5]    #north-south resolution
#bandtype = gdal.GetDataTypeName(band.DataType)
