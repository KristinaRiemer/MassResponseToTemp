library(dplyr)
library(ggplot2)

# Current year for all species
current_year = read.csv("results/species_stats.csv")
all_individuals = read.csv("results/stats_data.csv")

# R2 and slope distributions
par(mfrow = c(1, 2))
r = density(current_year$temp_r_squared)
plot(r, xlim = c(0, 1), xlab = "r^2", ylab = "", main = "Each species' r^2 dist from collection year temp")
polygon(r, col = "chartreuse3", border = "chartreuse3")
abline(v = mean(current_year$temp_r_squared), lty = 3)
abline(v = median(current_year$temp_r_squared), lty = 2)
legend("top", c("mean", "median"), lty = c(3, 2), bty = "n")

s = density(current_year$temp_slope, from = -2, to = 2)
plot(s, xlab = "slope", ylab = "", main ="Each species' slope dist from collection year temp")
polygon(s, col = "cornflowerblue", border = "cornflowerblue")
#abline(v = 0, col = "gray")
abline(v = mean(current_year$temp_slope), lty = 3)
abline(v = median(current_year$temp_slope), lty = 2)

# Effect of number individuals per species on r2 and slope
par(mfrow = c(1, 1))
plot(current_year$individuals, current_year$temp_r_squared)
plot(current_year$individuals, current_year$temp_slope, ylim = c(-10, 10))
abline(h = 0)

# Class-level r2 and slope
ggplot(current_year, aes(x = temp_r_squared)) + geom_density(aes(group = class, colour = class))
ggplot(current_year, aes(x = temp_slope)) + geom_density(aes(group = class, colour = class)) + scale_x_continuous(limits = c(-5, 5))

by_class = group_by(current_year, class)
class_summary = summarise(by_class,
                             count = n(),
                             rsquared_mean = mean(temp_r_squared),
                             rsquared_sd = sd(temp_r_squared),
                             rsquared_med = median(temp_r_squared),
                             slope_mean = mean(temp_slope),
                             slope_sd = sd(temp_slope),
                             slope_med = median(temp_slope))

#### STOPPED HERE

large_lat_temp_CY = current_year[current_year$genus_species %in% large_lat$clean_genus_species,]
plot(density(current_year$r_squared))
lines(density(large_lat_temp_CY$r_squared), col = "red")
plot(density(current_year$slope), xlim = c(-100, 100))
lines(density(large_lat_temp_CY$slope), col = "red")
abline(v = 0)
plot(large_lat_temp_CY$r_squared, large_lat_temp_CY$slope)

large_temp_temp_CY = current_year[current_year$genus_species %in% large_temp$clean_genus_species,]
plot(density(current_year$r_squared))
lines(density(large_temp_temp_CY$r_squared), col = "red")
plot(density(current_year$slope), xlim = c(-100, 100), ylim = c(0, 4))
lines(density(large_temp_temp_CY$slope), col = "red")
abline(v = 0)
plot(large_temp_temp_CY$r_squared, large_temp_temp_CY$slope)

# Mass-latitude relationships
lat_stats = read.csv("lat_stats.csv")
plot(density(lat_stats$r_squared))
plot(density(lat_stats$slope))

# Poster Figures 3
par(mfrow = c(1, 2))
lr = density(lat_stats$r_squared)
plot(lr, xlim = c(0, 1), xlab = "r^2", ylab = "", main = "Each species' r^2 dist from lat")
polygon(lr, col = "chartreuse3", border = "chartreuse3")
abline(v = mean(lat_stats$r_squared), lty = 3)
abline(v = median(lat_stats$r_squared), lty = 2)

ls = density(lat_stats$slope)
plot(ls, xlim = c(-20, 20), xlab = "slope", ylab = "", main ="Each species' slope dist from lat")
polygon(ls, col = "cornflowerblue", border = "cornflowerblue")
#abline(v = 0, col = "gray")
abline(v = mean(lat_stats$slope), lty = 3)
abline(v = median(lat_stats$slope), lty = 2)

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

# Spatial distribution of individuals
stats_data$map_long = ifelse(stats_data$longitude > 180, stats_data$longitude - 360, stats_data$longitude)
unique_coords = unique(stats_data[c("map_long", "decimallatitude")])
library(rworldmap)
map = getMap(resolution = "low")
plot(map)
points(unique_coords$map_long, unique_coords$decimallatitude, pch = 20, cex = 0.1, col = "red")
