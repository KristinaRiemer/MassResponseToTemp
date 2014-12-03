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
def get_value_at_point(raster_file, coordinates, band):
    """Determine value at chosen coordinates and band of raster
    
    Args:
        raster_file: file name of raster
        coordinates: chosen coordinates, should be longitude then latitude
        band: chosen band
    
    Returns: 
        Unpacked temperature at coordinates in band
    """
    entire_raster = gdal.Open(raster_file)    #opens raster file
    single_band = entire_raster.GetRasterBand(band)    #get desired band from raster stack
    geotrans_raster = entire_raster.GetGeoTransform()    #geotranforms raster to get gt points below
    #entire_raster = None    #closes file, considered good practice, causes to abort?
    x = int((coordinates[0] - geotrans_raster[0])/geotrans_raster[1])    #calculates offset for x
    y = int((coordinates[1] - geotrans_raster[3])/geotrans_raster[5])    #calculates offset for y
    band_array = single_band.ReadAsArray()    #creates array of temperatures for specific band
    packed_temp = band_array[y, x]    #outputs packed temp at offset from that array (short integer)
    add_offset = single_band.GetOffset()    #get offset to unpack
    scale_factor = single_band.GetScale()    #get scale factor to unpack
    unpacked_temp = add_offset + (packed_temp * scale_factor)
    return unpacked_temp

# Example to test function
p = (276.73, 30.83)
b = 1267
print get_value_at_point("air.mon.mean.v301.nc", p, b)

# Lag A with first individual
temp_file = "air.mon.mean.v301.nc"
individual_1_coords = individual_data.iloc[0][["Longitude", "Latitude"]]
# Need to add 360 to longitude so it's in correct format
individual_1_coords["Longitude"] = individual_1_coords["Longitude"] + 360
individual_1_band = individual_data.iloc[0]["stackID"]
#individual_1_current_temp = get_value_at_point(temp_file, individual_1_coords, individual_1_band)
#individual_1_lastyear_band = individual_1_band - 12
#individual_1_lastyear_temp = get_value_at_point(temp_file, individual_1_coords, individual_1_lastyear_band)
#individual_1_yearbefore_band = individual_1_lastyear_band - 12
#individual_1_yearbefore_temp = get_value_at_point(temp_file, individual_1_coords, individual_1_yearbefore_band)


all_july_stackIDs = []
def get_prev_julys(july_stackID):
    while july_stackID > 0:
        all_july_stackIDs.append(july_stackID)
        july_stackID -= 12

get_prev_julys(individual_1_band)

all_july_temps_individual1 = []
for current_stackID in all_july_stackIDs:
    temp = get_value_at_point(temp_file, individual_1_coords, current_stackID)
    all_july_temps_individual1.append(temp)
    


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
