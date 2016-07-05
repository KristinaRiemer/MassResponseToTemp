temp_stats = read.csv("temp_stats.csv")

# All lags across all species
plot(temp_stats$r_squared, temp_stats$slope, main = "all lags")
abline(v = mean(temp_stats$r_squared), h = mean(temp_stats$slope))
plot(density(temp_stats$r_squared), main = "all lags r2")
plot(density(temp_stats$slope), main = "all lags slope")

# Current year for all species
current_year = temp_stats[temp_stats$past_year == 0,]
plot(current_year$r_squared, current_year$slope, main = "zero lag")
abline(v = mean(current_year$r_squared), h = mean(current_year$slope))
plot(density(current_year$r_squared), main = "zero lag r2")
plot(density(current_year$slope), main = "zero lag slope")

# Comparing current year to all lags
mean(temp_stats$r_squared)
mean(current_year$r_squared)
mean(temp_stats$slope)
mean(current_year$slope)

# Looking at stats by lag year
boxplot(r_squared ~ past_year, data = temp_stats, outline = FALSE)
boxplot(slope ~ past_year, data = temp_stats, outline = FALSE)

library(ggplot2)
p = ggplot(temp_stats, aes(factor(past_year), r_squared))
p + geom_violin()
p2 = ggplot(temp_stats, aes(factor(past_year), slope))
p2 + geom_violin()

library(dplyr)
by_lag = group_by(temp_stats, past_year)
lags_summary = summarise(by_lag, 
          count = n(), 
          rsquared_mean = mean(r_squared), 
          rsquared_sd = sd(r_squared),
          rsquared_med = median(r_squared), 
          slope_mean = mean(slope), 
          slope_sd = sd(slope), 
          slope_med = median(slope))

plot(lags_summary$rsquared_mean, ylim = c(0.01, 0.1))
points(lags_summary$rsquared_med, col = "red")
plot(lags_summary$rsquared_sd)
plot(lags_summary$slope_mean)
points(lags_summary$slope_med, col = "red")
abline(h = 0)
plot(lags_summary$slope_sd)

plot(lags_summary$past_year, lags_summary$rsquared_mean, ylim = range(c(lags_summary$rsquared_mean - lags_summary$rsquared_sd,lags_summary$rsquared_mean + lags_summary$rsquared_sd)), pch = 19)
arrows(lags_summary$past_year, lags_summary$rsquared_mean - lags_summary$rsquared_sd, lags_summary$past_year, lags_summary$rsquared_mean + lags_summary$rsquared_sd, length = 0, angle = 90)

plot(lags_summary$past_year, lags_summary$slope_mean, ylim = range(c(lags_summary$slope_mean - lags_summary$slope_sd,lags_summary$slope_mean + lags_summary$slope_sd)), pch = 19)
arrows(lags_summary$past_year, lags_summary$slope_mean - lags_summary$slope_sd, lags_summary$past_year, lags_summary$slope_mean + lags_summary$slope_sd, length = 0, angle = 90)

# Looking at by number of individuals per each species
num_individuals = read.csv("num_individuals.csv")
temp_stats = merge(x = temp_stats, y = num_individuals, by = "genus_species", all.x = TRUE)
temp_stats$X.x = NULL
temp_stats$X.y = NULL
plot(temp_stats$individuals, temp_stats$r_squared)
plot(temp_stats$individuals, temp_stats$slope, ylim = c(-100, 100))

current_year = merge(x = current_year, y = num_individuals, by = "genus_species", all.x = TRUE)
current_year$X.x = NULL
current_year$X.y = NULL
plot(current_year$individuals, current_year$r_squared)
plot(current_year$individuals, current_year$slope, ylim = c(-10, 10))
abline(h = 0)

many_individuals = temp_stats[temp_stats$individuals > 206,]
few_individuals = temp_stats[temp_stats$individuals < 48,]

# Many vs few individuals current year
current_year_many = many_individuals[many_individuals$past_year == 0,]
current_year_few = few_individuals[few_individuals$past_year == 0,]

plot(density(current_year_many$r_squared))
lines(density(current_year_few$r_squared), col = "red")
mean(current_year_many$r_squared)
sd(current_year_many$r_squared)
mean(current_year_few$r_squared)
sd(current_year_few$r_squared)

plot(density(current_year_many$slope), xlim = c(-100, 100))
lines(density(current_year_few$slope), col = "red")
mean(current_year_many$slope)
sd(current_year_many$slope)
mean(current_year_few$slope)
sd(current_year_few$slope)

plot(current_year_many$r_squared, current_year_many$slope, ylim = c(-100, 100))
abline(v = mean(current_year_many$r_squared), h = mean(current_year_many$slope))
points(current_year_few$r_squared, current_year_few$slope, col = rgb(0, 0, 0, alpha = 0.2))
abline(v = mean(current_year_few$r_squared), h = mean(current_year_few$slope), col = rgb(0, 0, 0, alpha = 0.2))

# Mass-latitude relationships
lat_stats = read.csv("lat_stats.csv")
plot(density(lat_stats$r_squared))
plot(density(lat_stats$slope))
library(vioplot)
vioplot(lat_stats$slope, col = "white")
vioplot(lat_stats$r_squared, col = "white")
mean(lat_stats$r_squared)
sd(lat_stats$r_squared)
mean(lat_stats$slope)
median(lat_stats$slope)
sd(lat_stats$slope)

south_lat = lat_stats[lat_stats$hemisphere == "south",]
north_lat = lat_stats[lat_stats$hemisphere == "north",]
plot(density(north_lat$r_squared))
lines(density(south_lat$r_squared))
plot(density(north_lat$slope))
lines(density(south_lat$slope))

lat_stats = merge(x = lat_stats, y = num_individuals, by = "genus_species", all.x = TRUE)
lat_stats$X.x = NULL
lat_stats$X.y = NULL
plot(lat_stats$individuals, lat_stats$r_squared)
plot(lat_stats$individuals, lat_stats$slope)

# Mass-temp relationships by class
classes_raw = read.csv("class_raw.csv")
classes_raw = classes_raw[classes_raw$class != "",]
temp_stats = merge(x = temp_stats, y = classes_raw, by.x = "genus_species", by.y = "clean_genus_species", all.x = TRUE)
temp_stats$X = NULL

by_class = group_by(temp_stats, class)
class_summary = summarise(by_class, 
                          count = n(), 
                          rsquared_mean = mean(r_squared), 
                          rsquared_sd = sd(r_squared),
                          rsquared_med = median(r_squared), 
                          slope_mean = mean(slope), 
                          slope_sd = sd(slope), 
                          slope_med = median(slope))

ggplot(temp_stats, aes(x = r_squared)) + geom_density(aes(group = class, colour = class))
plot(class_summary$class, class_summary$rsquared_mean, ylim = range(c(class_summary$rsquared_mean - class_summary$rsquared_sd,class_summary$rsquared_mean + class_summary$rsquared_sd)), pch = 19)
points(class_summary$class, class_summary$rsquared_mean + class_summary$rsquared_sd)
points(class_summary$class, class_summary$rsquared_mean - class_summary$rsquared_sd)

ggplot(temp_stats, aes(x = slope)) + geom_density(aes(group = class, colour = class)) + scale_x_continuous(limits = c(-10, 10))
plot(class_summary$class, class_summary$slope_mean, ylim = range(c(class_summary$slope_mean - class_summary$slope_sd,class_summary$slope_mean + class_summary$slope_sd)), pch = 19)
points(class_summary$class, class_summary$slope_mean + class_summary$slope_sd)
points(class_summary$class, class_summary$slope_mean - class_summary$slope_sd)

# Mass-temp relationships for species with large latitude range
library(readr)
stats_data = read_csv("stats_data.csv")
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
plot(density(temp_stats$slope), xlim = c(-100, 100))
lines(density(large_lat_temp$slope), col = "red")
abline(v = 0)
plot(large_lat_temp$r_squared, large_lat_temp$slope)

large_lat_temp_CY = current_year[current_year$genus_species %in% large_lat$clean_genus_species,]
plot(density(current_year$r_squared))
lines(density(large_lat_temp_CY$r_squared), col = "red")
plot(density(current_year$slope), xlim = c(-100, 100))
lines(density(large_lat_temp_CY$slope), col = "red")
abline(v = 0)
plot(large_lat_temp_CY$r_squared, large_lat_temp_CY$slope)

# Mass-temp relationships for species with large temperature range
species_summary$temp_diff = species_summary$temp_max - species_summary$temp_min
hist(species_summary$temp_diff)
large_temp = species_summary[species_summary$temp_diff > 27.68,] #top quartile of lat range
large_temp_temp = temp_stats[temp_stats$genus_species %in% large_temp$clean_genus_species,]
plot(density(temp_stats$r_squared))
lines(density(large_temp_temp$r_squared), col = "red")
plot(density(temp_stats$slope), xlim = c(-100, 100))
lines(density(large_temp_temp$slope), col = "red")
abline(v = 0)
plot(large_temp_temp$r_squared, large_temp_temp$slope)

large_temp_temp_CY = current_year[current_year$genus_species %in% large_temp$clean_genus_species,]
plot(density(current_year$r_squared))
lines(density(large_temp_temp_CY$r_squared), col = "red")
plot(density(current_year$slope), xlim = c(-100, 100))
lines(density(large_temp_temp_CY$slope), col = "red")
abline(v = 0)
plot(large_temp_temp_CY$r_squared, large_temp_temp_CY$slope)

# TODO: 
# Removing temporal: species with only 5 years range (like previous Bergmann studies)
# Removing spatial: lots of points across time with short spatial range
# Plot # individuals vs r2/r
# Look at species with really high slopes
# Something about spatial distribution? 
