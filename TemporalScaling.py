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


# For each individual, get temperatures for each July starting with the initial, 
# i.e., when collected, year and every previous year until 1900. 

# Getting temperature and individuals datasets ready
temp_file = "air.mon.mean.v301.nc"
# Need to add 360 to longitude so it's in correct format
individual_data["Longitude.Transformed"] = individual_data["Longitude"] + 360
# Create subset of individuals dataset to test function for multiple individuals
subset_individual_data = individual_data.iloc[0:10]

# Get all July stackID values for an individual
def get_prev_julys(july_stackID):
    all_july_stackIDs = []
    while july_stackID > 0:
        all_july_stackIDs.append(july_stackID)
        july_stackID -= 12
    return all_july_stackIDs

# Use for loop to run each individual's stackID through function
# Each list is for one individual and contains all July years
subset_individuals = []
for individual_year in subset_individual_data["stackID"]:
    each_individual = get_prev_julys(individual_year)
    subset_individuals.append(each_individual)

# Use temp extraction function to get all July temps for an individual
def get_temps(years, file_name, coords):
    all_temps = []    
    for year in years: 
        each_temp = get_value_at_point(file_name, coords, year)
        all_temps.append(each_temp)
    return all_temps

# Use for loop to run each individual's July stackIDS to get temps
subset_temps = []
for i in range(len(subset_individual_data)):
    all_temps = get_temps(subset_individuals[i], temp_file, 
                          individual_data.iloc[i][["Longitude.Transformed", "Latitude"]])
    subset_temps.append(all_temps)

