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
    """Get stackID for chosen month and year
    
    Args:
        year: Year for stackID
        month_code: Code for chosen month
    
    Returns:
        StackID for month and year
    """
    stackID = year * 12 - month_code
    return stackID


def get_temps_list(raster_file, coordinates, bands): 
    """Get temperatures for lists of locations and stackIDs
    
    Args: 
        raster_file: File of temperatures
        coordinates: Dataframe columns with location coordinates
        band: Dataframe column with stackID corresponding to desired month and year
    
    Returns: 
        List of temperatures for coordinates and stackIDs
    """
    open_file = gdal.Open(raster_file)
    all_temps = []
    for i in range(len(bands)): 
        ID_value = bands.iloc[i]
        each_ind_temps = []
        for j in range(bands.iloc[i], bands.iloc[i] + 12): 
            single_band = open_file.GetRasterBand(j)
            geotrans_raster = open_file.GetGeoTransform()
            x = int((coordinates.iloc[i][0] - geotrans_raster[0])/geotrans_raster[1])
            y = int((coordinates.iloc[i][1] - geotrans_raster[3])/geotrans_raster[5])
            band_array = single_band.ReadAsArray()
            packed_temp = band_array[y, x]
            add_offset = single_band.GetOffset()
            scale_factor = single_band.GetScale()
            scale_factor = np.float32(scale_factor)
            unpacked_temp = add_offset + (packed_temp * scale_factor)                    
            each_ind_temps.append(unpacked_temp)
        year_avg = np.mean(each_ind_temps)
        all_temps.append(year_avg)
    open_file = None
    return all_temps

def remove_species(dataframe, species_col): 
    """Remove species from dataframe that have fewer than 60 individuals due to
    a lack of temperature data
    
    Args: 
        dataframe: initial dataframe
        species_col: column that contains species names
    
    Returns: 
        Dataframe that contains species with >60 individuals
    
    """
    insufficient_species = []
    for species, species_data in dataframe.groupby(species_col): 
        if len(species_data["row_index"].unique()) < 60: 
            insufficient_species.append(species)
    sufficient_species_df = dataframe[dataframe[species_col].isin(insufficient_species) == False]
    return sufficient_species_df

def lin_reg(dataset, speciesID_col): 
    # TODO: Add docstring to match TL py script
    temp_pdf = PdfPages("results_expand_thresholds/temp_currentyear.pdf")
    lat_pdf = PdfPages("results_expand_thresholds/lat.pdf")
    stats_list = []
    for species, species_data in dataset.groupby(speciesID_col): 
        sp_class = species_data["class"].unique()[0]
        sp_order = species_data["ordered"].unique()[0]
        sp_family = species_data["family"].unique()[0]
        temp_linreg = smf.ols(formula = "massing ~ temperature", data = species_data).fit()
        plt.figure()
        plt.plot(species_data["temperature"], species_data["massing"], "bo")
        plt.plot(species_data["temperature"], temp_linreg.fittedvalues, "r-")
        plt.xlabel("Mean current year temperature")
        plt.ylabel("Mass (g)")
        plt.suptitle(species)
        temp_pdf.savefig()
        plt.close()
        if species_data["decimallatitude"].mean() < 0: 
            hemisphere = "south"
        else: 
            hemisphere = "north"
        lat_linreg = smf.ols(formula = "massing ~ abs(decimallatitude)", data = species_data).fit()
        plt.figure()
        plt.plot(abs(species_data["decimallatitude"]), species_data["massing"], "bo")
        plt.plot(abs(species_data["decimallatitude"]), lat_linreg.fittedvalues, "r-")
        plt.xlabel("Latitude")
        plt.ylabel("Mass (g)")
        plt.title(species)
        plt.figtext(0.05, 0.05, hemisphere)
        lat_pdf.savefig()
        plt.close()
        stats_list.append({"genus_species": species, "class": sp_class, "order": sp_order, "family": sp_family, "individuals": len(species_data["row_index"].unique()),  "hemisphere": hemisphere, "temp_r_squared": temp_linreg.rsquared, "temp_slope": temp_linreg.params[1], "temp_slope_SE": temp_linreg.bse[1], "temp_pvalue": temp_linreg.f_pvalue, "lat_r_squared": lat_linreg.rsquared, "lat_slope": lat_linreg.params[1], "lat_pvalue": lat_linreg.f_pvalue})    
    temp_pdf.close()
    lat_pdf.close()
    stats_df = pd.DataFrame(stats_list)
    return stats_df

import time
begin_time = time.time()

# Datasets
individual_data = pd.read_csv("results_expand_thresholds/CompleteDatasetVN.csv", usecols = ["row_index", "clean_genus_species", "class", "ordered", "family", "year", "longitude", "decimallatitude", "massing", "citation", "license", "isfossil"])
individual_data = individual_data[individual_data["isfossil"] == 0]
#full_individual_data = pd.read_csv("CompleteDatasetVN.csv", usecols = ["row_index", "clean_genus_species", "class", "ordered", "family", "year", "longitude", "decimallatitude", "massing", "citation", "license", "isfossil"])
#species_list = full_individual_data["clean_genus_species"].unique().tolist()
#species_list = sorted(species_list)
#individual_data = full_individual_data[full_individual_data["clean_genus_species"].isin(species_list[18:20])]

gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temp_file = "air.mon.mean.v301.nc"

# List of months with corresponding stackID codes
month_codes = create_month_codes_dict(22799, 22787, -1)

# Get stackIDS for January of collection year for each individual
individual_data["stackID"] = get_stackID(individual_data["year"], month_codes["January"])

# Avoiding multiple temp lookups for same location/year combinations
temp_lookup = individual_data[["longitude", "decimallatitude", "stackID"]]
temp_lookup = temp_lookup.drop_duplicates()

# Get mean temperature for collection year
temp_lookup["temperature"] = get_temps_list(temp_file, temp_lookup[["longitude", "decimallatitude"]], temp_lookup["stackID"])
temp_data = individual_data.merge(temp_lookup)

# Remove rows with missing data values (i.e., -9.96921e+36)
temp_data = temp_data[temp_data["temperature"] > -10000]

# Remove species with less than 60 individuals
stats_data = remove_species(temp_data, "clean_genus_species")

# Linear regression for mass with temp and latitude for all species, both plots and df
species_stats = lin_reg(stats_data, "clean_genus_species")

# Calculate correlation coefficient for both linear regressions
species_stats["temp_r"] = np.where(species_stats["temp_slope"] < 0, -np.sqrt(species_stats["temp_r_squared"]), np.sqrt(species_stats["temp_r_squared"]))
species_stats["lat_r"] = np.where(species_stats["lat_slope"] < 0, -np.sqrt(species_stats["lat_r_squared"]), np.sqrt(species_stats["lat_r_squared"]))

end_time = time.time()
total_time = (end_time - begin_time) / 60

# Save dataframes with final data and species statistics
species_stats.to_csv("results_expand_thresholds/species_stats.csv")
stats_data.to_csv("results_expand_thresholds/stats_data.csv")
