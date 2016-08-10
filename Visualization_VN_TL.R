library(dplyr)
library(ggplot2)
library(readr)

temp_stats = read.csv("temp_stats.csv")
num_individuals = read.csv("num_individuals.csv") #initial number of individuals only
temp_stats = merge(x = temp_stats, y = num_individuals, by = "genus_species", all.x = TRUE)
temp_stats$X.x = NULL
temp_stats$X.y = NULL
classes_raw = read.csv("class_raw.csv")
classes_raw = classes_raw[classes_raw$class != "",]
temp_stats = merge(x = temp_stats, y = classes_raw, by.x = "genus_species", by.y = "clean_genus_species", all.x = TRUE)
temp_stats$X = NULL

stats_data = read_csv("stats_data.csv")

# All lags across all species
plot(temp_stats$r_squared, temp_stats$slope, main = "all lags")
abline(v = mean(temp_stats$r_squared), h = mean(temp_stats$slope))
plot(density(temp_stats$r_squared), main = "all lags r2")
plot(density(temp_stats$slope), main = "all lags slope")

### TODO: read in current year csv instead, use histograms instead
# Comparing current year to all lags
# mean(temp_stats$r_squared)
# mean(current_year$r_squared)
# mean(temp_stats$slope)
# mean(current_year$slope)

# Looking at stats by lag year
by_lag = group_by(temp_stats, past_year)
lags_summary = summarise(by_lag, 
                         num_species = n(), 
                         rsquared_mean = mean(r_squared), 
                         rsquared_sd = sd(r_squared),
                         rsquared_med = median(r_squared), 
                         slope_mean = mean(slope), 
                         slope_sd = sd(slope), 
                         slope_med = median(slope))

plot(temp_stats$past_year, temp_stats$r_squared, pch = 20, cex = 0.3, col = "chartreuse3", xlab = "past year", ylab = "r^2")
points(lags_summary$past_year, lags_summary$rsquared_med, pch = "-")
points(lags_summary$past_year, lags_summary$rsquared_mean, col = "red", pch = "-")
legend(x = "topleft", legend = c("species", "mean"), pch = c(20, 20), col = c("chartreuse3", "black"), bty = "n")
plot(temp_stats$past_year, temp_stats$slope, pch = 20, cex = 0.3, col = "cornflowerblue", ylim = c(-100, 100), xlab = "past year", ylab = "slope")
points(lags_summary$past_year, lags_summary$slope_med, pch = "-")
points(lags_summary$past_year, lags_summary$slope_mean, col = "red", pch = "-")
legend(x = "bottomright", legend = c("species", "mean"), pch = c(20, 20), col = c("cornflowerblue", "black"), bty = "n")

# Looking at by number of individuals per each species
plot(temp_stats$individuals, temp_stats$r_squared)
plot(temp_stats$individuals, temp_stats$slope, ylim = c(-100, 100))

# Mass-temp relationships by class
by_class = group_by(temp_stats, class)
class_summary = summarise(by_class, 
                          count = n(), 
                          rsquared_mean = mean(r_squared), 
                          rsquared_sd = sd(r_squared),
                          rsquared_med = median(r_squared), 
                          slope_mean = mean(slope), 
                          slope_sd = sd(slope), 
                          slope_med = median(slope))

par(mfrow = c(1, 1))

ggplot(temp_stats, aes(x = r_squared)) + geom_density(aes(group = class, colour = class))
ggplot(temp_stats, aes(x = slope)) + geom_density(aes(group = class, colour = class)) + scale_x_continuous(limits = c(-10, 10))

# Change in number of individuals per species across lag years
by_species_lag = group_by(stats_data, clean_genus_species, lag)
species_lag_summary = summarise(by_species_lag, count = n())
plot(species_lag_summary$lag, species_lag_summary$count, pch = 20, cex = 0.5)

# Mass-temp relationships for species with large latitude range
by_species = group_by(stats_data, clean_genus_species)
species_summary = summarise(by_species, 
                            count = n(), 
                            lat_min = min(decimallatitude), 
                            lat_max = max(decimallatitude), 
                            temp_min = min(july_temps), 
                            temp_max = max(july_temps))
species_summary$lat_diff = species_summary$lat_max - species_summary$lat_min
hist(species_summary$lat_diff)
large_lat = species_summary[species_summary$lat_diff > 41.1,] #top quartile of lat range
large_lat_temp = temp_stats[temp_stats$genus_species %in% large_lat$clean_genus_species,]
plot(density(temp_stats$r_squared))
lines(density(large_lat_temp$r_squared), col = "red")
plot(density(temp_stats$slope, from = -20, to = 20), xlim = c(-20, 20))
lines(density(large_lat_temp$slope, from = -20, to = 20), col = "red")
abline(v = 0)
plot(large_lat_temp$r_squared, large_lat_temp$slope)

# Mass-temp relationships for species with large temperature range
species_summary$temp_diff = species_summary$temp_max - species_summary$temp_min
hist(species_summary$temp_diff)
large_temp = species_summary[species_summary$temp_diff > 27.68,] #top quartile of temp range
large_temp_temp = temp_stats[temp_stats$genus_species %in% large_temp$clean_genus_species,]
plot(density(temp_stats$r_squared))
lines(density(large_temp_temp$r_squared), col = "red")
plot(density(temp_stats$slope, from = -20, to = 20), xlim = c(-20, 20))
lines(density(large_temp_temp$slope, from = -20, to = 20), col = "red")
abline(v = 0)
plot(large_temp_temp$r_squared, large_temp_temp$slope)
