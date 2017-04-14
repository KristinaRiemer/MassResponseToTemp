# Check for pacman installation
if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

# Install necessary packages
pacman::p_load(readr, stringr, taxize, spatstat, dplyr, rdataretriever, plyr, ggplot2, cowplot)
