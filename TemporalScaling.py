from __future__ import division

# Read in individual data and create subset to test functions
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
individual_data["Longitude.Transformed"] = individual_data["Longitude"] + 360
subset_individual_data = individual_data.iloc[0:10]

# Packages for reading in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")

# Temperature dataset
temp_file = "air.mon.mean.v301.nc"

def get_prev_years(stackID):
    """Get stackID values for same months in all previous years until 1900
    
    Args:
        stackID: initial/current stackID value
    
    Returns:
        List containing initial/current stackID value and previous years' stackIDs
    """
    all_stackIDs = []
    while stackID > 0:
        all_stackIDs.append(stackID)
        stackID -= 12
    return all_stackIDs

# Get all July stackID values for each individual in subset dataset
subset_stackIDs = []
for individual_stackID in subset_individual_data["stackID"]:
    individual_stackIDs = get_prev_years(individual_stackID)
    subset_stackIDs.append(individual_stackIDs)

def get_temp_at_point(raster_file, coordinates, band):
    """Determine temperature value at chosen coordinates and band of raster
    
    Args:
        raster_file: file name of raster
        coordinates: chosen coordinates, order is longitude and latitude
        band: chosen band (i.e., month)
    
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

def get_individuals_temps(years_list, file_name, coordinates):
    """Get all temperature values for corresponding stackIDs for an individual
    
    Args: 
        years_list: list of stackID values (i.e., months)
        file_name: name of raster file
        coordinates: longitude and latitude of individual
    
    Returns: 
        List containing all temperatures for individual
    """
    all_individuals_temps = []    
    for current_year in years_list: 
        each_temp = get_temp_at_point(file_name, coordinates, current_year)
        all_individuals_temps.append(each_temp)
    return all_individuals_temps

# Get all temps for corresponding July stackIDs for each individual in subset dataset
subset_temps = []
for i in range(len(subset_individual_data)):
    subset_individuals_temps = get_individuals_temps(subset_stackIDs[i], temp_file, 
                          individual_data.iloc[i][["Longitude.Transformed", "Latitude"]])
    subset_temps.append(subset_individuals_temps)

# Create final dataset
subset_temps = pd.DataFrame(subset_temps)
year_lag_july_subset = pd.concat([subset_individual_data[["Species.Genus", "Mass", 
                                "Year.Collected"]], subset_temps])

# Can't rename temperature columns or concatenate data with columns in desired order
#subset_temps = subset_temps.rename(columns=lambda x: str(x))
#subset_temps = subset_temps.rename(columns=lambda x: x.replace("", "Past.Year." + ""))
