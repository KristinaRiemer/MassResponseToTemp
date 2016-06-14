from __future__ import division
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import pandas as pd
import numpy as np
import calendar
from osgeo import gdal
import statsmodels.formula.api as smf
import time
from joblib import Parallel, delayed

def duplicate_rows(dataset, formula): 
    """Duplicate each row of dataset using number in created column
    
    Args: 
        dataset: Pandas dataframe to be duplicated
        formula: Used to create column that specifies number of duplicates
    
    Returns: 
        Dataframe with rows duplicated specified number of times
    """
    dataset["number_duplicates"] = formula
    duplicates_dataset = dataset.loc[np.repeat(dataset.index.values, dataset["number_duplicates"])]
    return duplicates_dataset

def create_lag_column(dataset_chunks): 
    dataset_chunks["lag"] = np.asarray(range(len(dataset_chunks)))
    return dataset_chunks

def applyParallel(dataset_grouped, func): 
    results = Parallel(n_jobs = -2, verbose = 5) (delayed(func)(group) for name, group in dataset_grouped)
    return pd.concat(results)

def create_month_codes_dict(jan_code, dec_code, diff):
    """Create dictionary of month names and corresponding codes
    
    Args: 
        jan_code: Code corresponding to month of January
        dec_code: Code corresponding to month of December
        diff: What value to add/subtract between each month code
    
    Returns: 
        Dictionary of month names and codes
    """
    month_names = []
    for each_month in range(1, 13):
        month_names.append(calendar.month_name[each_month])
    codes = range(jan_code, dec_code, diff)
    month_codes = {}
    for month, code in zip(month_names, codes):
        month_codes[month] = code
    return month_codes

def get_stackID(year, month_code):
    # TODO: incorporate 3 month average option
    """Get stackID for chosen month and year
    
    Args:
        year: Year for stackID
        month_code: Code for chosen month
    
    Returns:
        StackID for month and year
    """
    stackID = year * 12 - month_code
    return stackID


def get_temps_list(coordinates, bands): 
    # FIXME: Might have to move raster open inside for loop to decrease lookup time
    """Get temperatures for lists of locations and stackIDs
    
    Args: 
        raster_file: File of temperatures
        coordinates: Dataframe columns with location coordinates
        band: Dataframe column with stackID corresponding to desired month and year
    
    Returns: 
        List of temperatures for coordinates and stackIDs
    """
    open_file = gdal.Open(temp_file) #add raster file back in as argument
    all_temps = []
    for i in range(len(bands)): 
        single_band = open_file.GetRasterBand(bands.iloc[i])
        geotrans_raster = open_file.GetGeoTransform()
        x = int((coordinates.iloc[i][0] - geotrans_raster[0])/geotrans_raster[1])
        y = int((coordinates.iloc[i][1] - geotrans_raster[3])/geotrans_raster[5])
        band_array = single_band.ReadAsArray()
        packed_temp = band_array[y, x]
        add_offset = single_band.GetOffset()
        scale_factor = single_band.GetScale()
        unpacked_temp = add_offset + (packed_temp * scale_factor)
        all_temps.append(unpacked_temp)
    open_file = None
    return all_temps

def remove_species(dataframe, species_col): 
    """Remove species from dataframe that have fewer than 30 individuals due to
    a lack of temperature data
    
    Args: 
        dataframe: initial dataframe
        species_col: column that contains species names
    
    Returns: 
        Dataframe that contains species with >30 individuals
    
    """
    insufficient_species = []
    for species, species_data in dataframe.groupby(species_col): 
        if len(species_data["row_index"].unique()) < 30: 
            insufficient_species.append(species)
    sufficient_species_df = dataframe[dataframe[species_col].isin(insufficient_species) == False]
    return sufficient_species_df

def linear_regression(dataset, speciesID_col, lag_col):
    # FIXME: Docstring should be more descriptive
    """Plot linear regression for all lags of each species, create dataframe of linear regression
    r2 and slope for all lags of each species, and plot latter for each species
    
    Args: 
        dataset: Dataframe containing temperature for each individual at all lags
        speciesID_col: Dataframe column of species identification
        lag_col: Dataframe column of lag
    
    Returns: 
        For each species, many linear regression plots and one stats plot; stats dataframe
    """
    stats_pdf = PdfPages("all_stats.pdf")
    all_stats = pd.DataFrame()
    for species, species_data in dataset.groupby(speciesID_col):
        linreg_pdf = PdfPages(species + "_linreg.pdf")
        stats_list = []
        for lag, lag_data in species_data.groupby(lag_col): 
            if len(lag_data) > 15: 
                linreg = smf.ols(formula = "mass ~ july_temps", data = lag_data).fit()
                plt.figure()
                plt.plot(lag_data["july_temps"], lag_data["mass"], "bo")
                plt.plot(lag_data["july_temps"], linreg.fittedvalues, "r-")
                plt.xlabel("Temperature from year lag " + str(lag))
                plt.ylabel("Mass(g)")
                linreg_pdf.savefig()
                plt.close()
                stats_list.append({"genus_species": species, "past_year": lag, "r_squared": linreg.rsquared, "slope": linreg.params[1]})
        linreg_pdf.close()
        stats_df = pd.DataFrame(stats_list)
        plt.subplot(2, 1, 1)
        plt.plot(stats_df["past_year"], stats_df["r_squared"], color = "purple", marker = "o", linestyle = "None")
        plt.axhline(y = 1, color = "purple", linestyle = "--", linewidth = 3)
        plt.ylabel("R^2")
        plt.subplot(2, 1, 2)
        plt.plot(stats_df["past_year"], stats_df["slope"], color = "yellow", marker = "o", linestyle = "None")
        plt.axhline(y = 0, color = "yellow", linestyle = "--", linewidth = 3)
        plt.suptitle(species)
        plt.xlabel("Lag")
        plt.ylabel("Slope")
        stats_pdf.savefig()
        plt.close()
        all_stats = all_stats.append(stats_df)
    stats_pdf.close()
    return all_stats

begin_time = time.time()

# Datasets
#individual_data = pd.read_csv("CompleteDatasetVN.csv", usecols = ["clean_genus_species", "year", "longitude", "decimallatitude", "mass"])
full_individual_data = pd.read_csv("CompleteDatasetVN.csv", usecols = ["row_index", "clean_genus_species", "year", "longitude", "decimallatitude", "mass"])
species_list = full_individual_data["clean_genus_species"].unique().tolist()
species_list = sorted(species_list)
individual_data = full_individual_data[full_individual_data["clean_genus_species"].isin(species_list[0:10])]

gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temp_file = "air.mon.mean.v301.nc"

# Duplicate individual rows based on number of years between 1900 and collection year
duplicates_data = duplicate_rows(individual_data, individual_data["year"] - 1899)

# Create year lag column for each individual
lag_data = applyParallel(duplicates_data.groupby(level = 0), create_lag_column)

# Add year for temperature lookup
lag_data["temp_year"] = lag_data["year"] - lag_data["lag"]

# List of months with corresponding stackID codes
month_codes = create_month_codes_dict(22799, 22787, -1)

# Get stackIDs for July and year
lag_data["stackID_july"] = get_stackID(lag_data["temp_year"], month_codes["July"])

# Avoiding multiple temp lookups for same location/year combinations
temp_lookup = lag_data[["longitude", "decimallatitude", "stackID_july"]]
temp_lookup = temp_lookup.drop_duplicates()

# Get temperatures for July
temp_lookup["july_temps"] = get_temps_list(temp_lookup[["longitude", "decimallatitude"]], temp_lookup["stackID_july"])
temp_data = lag_data.merge(temp_lookup)

# Remove rows with missing data values (i.e., 3276.7)
temp_data = temp_data[temp_data["july_temps"] < 3276]

# Remove species with less than 30 individuals
stats_data = remove_species(temp_data, "clean_genus_species")

# Create linear regression and stats plots for each species, and dataframe with r2 and slope
linreg_stats = linear_regression(stats_data, "clean_genus_species", "lag")
linreg_stats.to_csv("species_stats.csv")

end_time = time.time()
total_time = (end_time - begin_time) / 60 #in mins