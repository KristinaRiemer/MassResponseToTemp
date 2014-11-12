from __future__ import division

# read in individual and species data
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
species_data = pd.read_csv("FinalSpeciesList.csv")

# read in temperature data
from scipy.io import netcdf
temperature_data = netcdf.netcdf_file("air.mon.mean.v301.nc", "r")
