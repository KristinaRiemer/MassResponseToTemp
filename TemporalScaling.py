from __future__ import division

# Read in individual data and create subset to test functions
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
individual_data["Longitude.Transformed"] = individual_data["Longitude"] + 360
subset_individual_data = individual_data.iloc[0:10]

# Read in new individual data
new_individual_data = pd.read_csv("CompleteDatasetUS.csv")
subset_new_individual_data = new_individual_data.iloc[0:10]

## Comparing datasets
#from pandas.util.testing import assert_frame_equal
#assert_frame_equal(individual_data["Species.Genus"], new_individual_data["genus_species"])
colnames = subset_individual_data.columns
new_colnames = subset_new_individual_data.columns

# Packages for reading in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")

# Temperature dataset
temp_file = "air.mon.mean.v301.nc"

# List of months with corresponding codes for stackID
# stackID = year * 12 - monthcode
import calendar
month_names = []
for each_month in range(1, 13):
    month_names.append(calendar.month_name[each_month])
month_codes = pd.DataFrame(month_names, columns = ["month"])
month_codes["code"] = range(22799, 22787, -1)
    
# How to use this as a lookup table?
month_codes["code"][month_codes["month"] == "July"]

# Only monthly average for now, later add 3 month average option
def get_all_stackIDs(current_year, month_code):
    """Get stackIDs for chosen month in current and previous years until 1900
    
    Args:
        current_year: Collection year for first stackID
        month_code: Code for chosen month
    
    Returns:
        List of stackIDs for chosen month from current year back to 1900
    """
    current_stackID = current_year * 12 - month_code
    all_stackIDs = []
    while current_stackID > 0:
        all_stackIDs.append(current_stackID)
        current_stackID -= 12
    return all_stackIDs

# Get all July stackID values for each individual in subset dataset
july_code = 22793
subset_july_stackIDS = []
for each_year in subset_new_individual_data["year"]:
    each_year_stackIDs = get_all_stackIDs(each_year, july_code)
    subset_july_stackIDS.append(each_year_stackIDs)

#def get_prev_years(stackID):
    #"""Get stackID values for same month in all previous years until 1900
    
    #Args:
        #stackID: initial/current stackID value
    
    #Returns:
        #List containing initial/current stackID value and previous years' stackIDs
    #"""
    #all_stackIDs = []
    #while stackID > 0:
        #all_stackIDs.append(stackID)
        #stackID -= 12
    #return all_stackIDs

## Get all July stackID values for each individual in subset dataset
#subset_stackIDs = []
#for individual_stackID in subset_individual_data["stackID"]:
    #individual_stackIDs = get_prev_years(individual_stackID)
    #subset_stackIDs.append(individual_stackIDs)

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
# all in single pdf, get pvalue and r2 from lin reg for each subset

# What do do about RuntimeWarning? Moving close around didn't work

# See dir(linreg_results) for all possible parts of lin reg summary

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import statsmodels.api as sm
all_of_them = []
pp = PdfPages("all_figs.pdf")
linreg_stats = []
for unique_species in year_lag_july_subset["Species.Genus"].unique()[0], year_lag_july_subset["Species.Genus"].unique()[-1]:
    unique_species_data = year_lag_july_subset[year_lag_july_subset["Species.Genus"] == unique_species]
    for current_past_year in column_names:
        unique_year_data = unique_species_data[[col for col in unique_species_data.columns if col == current_past_year]]
        unique_year_mass = pd.concat([unique_species_data["Mass"], unique_year_data], axis=1)
        all_of_them.append(unique_year_mass)
        if np.all(pd.notnull(unique_year_mass.iloc[:,1])):
            plt.figure()
            plt.plot(unique_year_mass.iloc[:,1], unique_year_mass.iloc[:,0], "bo")
            pp.savefig()
            linreg = sm.regression.linear_model.OLS(unique_year_mass.iloc[:,0], unique_year_mass.iloc[:,1])
            linreg_results = linreg.fit()
            r2 = linreg_results.rsquared
            pval = linreg_results.pvalues
            slope = linreg_results.params
            linreg_stats.append([pval, r2, slope])
pp.close()


# Using pandas groupby, what is the benefit? 
by_species = year_lag_july_subset.groupby("Species.Genus")
for species, species_data in by_species:
    avg_mass = np.mean(species_data["Mass"])
    print "Avg mass of {} is {}" .format(species, avg_mass)

pp2 = PdfPages("all_figs_2.pdf")
by_species = year_lag_july_subset.groupby("Species.Genus")
for species, species_data in by_species:
    for current_past_year in column_names:







