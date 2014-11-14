from __future__ import division

# read in individual and species data
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
species_data = pd.read_csv("FinalSpeciesList.csv")

# read in temperature data
import numpy as np
import matplotlib.pyplot as plt
import netCDF4

temperature_data = netCDF4.Dataset("air.mon.mean.v301.nc")

