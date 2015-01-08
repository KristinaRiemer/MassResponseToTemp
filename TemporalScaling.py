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
# Need to change range to be automated for greatest length
column_names = ["Past_Year_{}" .format(year) for year in range(41)]
subset_temps = pd.DataFrame(subset_temps, columns=column_names)
year_lag_july_subset = pd.concat([subset_individual_data[["Species.Genus", "Mass", 
                                "Year.Collected"]], subset_temps], axis=1)



# Subset dataset by unique species with unique past years, select on those subsets
# with all temps (i.e., no nulls in past year col), graph those subsets and save
# all in single pdf

# What do do about RuntimeWarning? Moving close around didn't work

# Need to do lin reg of each of these subsets, get pvalues and r2 for each

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
#all_of_them = []
pp = PdfPages("all_figs.pdf")
for unique_species in year_lag_july_subset["Species.Genus"].unique():
    unique_species_data = year_lag_july_subset[year_lag_july_subset["Species.Genus"] == unique_species]
    for current_past_year in column_names:
        unique_year_data = unique_species_data[[col for col in unique_species_data.columns if col == current_past_year]]
        unique_year_mass = pd.concat([unique_species_data["Mass"], unique_year_data], axis=1)
        #all_of_them.append(unique_year_mass)
        if np.all(pd.notnull(unique_year_mass.iloc[:,1])):
            plt.figure()
            plt.plot(unique_year_mass.iloc[:,1], unique_year_mass.iloc[:,0], "bo")
            pp.savefig()
pp.close()


# Linreg walkthrough: http://www.datarobot.com/blog/ordinary-least-squares-in-python/
# Doing example with last species in subset for past year 0

import statsmodels.api as sm
sm.regression.linear_model.OLS(unique_year_mass["Mass"], unique_year_mass["Past_Year_40"])

example_data = [[17.1, 29.0], [25.2, 24.4], [25.2, 26.4], [17.7, 21.0], [17.9, 25.5]]
example_data = pd.DataFrame(example_data)
example_data.columns = ["temp", "mass"]

testing_linreg = sm.regression.linear_model.OLS(example_data["mass"], example_data["temp"])
results = testing_linreg.fit()
print(results.summary())
print(results.rsquared)
print(results.pvalues)

# See dir(results) for all possible parts of lin reg summary
