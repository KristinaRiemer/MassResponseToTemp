library(dplyr)
library(ggplot2)

# Current year for all species
current_year = read.csv("results/species_stats.csv")
all_individuals = read.csv("results/stats_data.csv")

# R2 and slope distributions
par(mfrow = c(1, 3))
r = density(current_year$temp_r_squared)
plot(r, xlim = c(0, 1), xlab = "r^2", ylab = "", main = "Each species' r^2 dist from collection year temp")
polygon(r, col = "chartreuse3", border = "chartreuse3")
abline(v = mean(current_year$temp_r_squared), lty = 3)
abline(v = median(current_year$temp_r_squared))
legend("top", c("mean", "median"), lty = c(3, 1), bty = "n")

s = density(current_year$temp_slope, from = -10, to = 10)
plot(s, xlab = "slope", ylab = "", main ="Each species' slope dist from collection year temp")
polygon(s, col = "cornflowerblue", border = "cornflowerblue")
#abline(v = 0, col = "gray")
abline(v = mean(current_year$temp_slope), lty = 3)
abline(v = median(current_year$temp_slope))

c = density(current_year$temp_r)
plot(c, xlim = c(-1, 1), xlab = "r", ylab = "", main = "Each species' r dist from collection year temp")
polygon(c, col = "red", border = "red")
abline(v = c(0, -1, 1), col = "gray")
abline(v = mean(current_year$temp_r), lty = 3)
abline(v = median(current_year$temp_r))

# Effect of number individuals per species on r2 and slope
par(mfrow = c(1, 1))
plot(current_year$individuals, current_year$temp_r_squared)
plot(current_year$individuals, current_year$temp_slope, ylim = c(-10, 10))
abline(h = 0)
plot(current_year$individuals, current_year$temp_r)
abline(h = 0)

# Class-level r2 and slope
ggplot(current_year, aes(x = temp_r_squared)) + geom_density(aes(group = class, colour = class))
ggplot(current_year, aes(x = temp_slope)) + geom_density(aes(group = class, colour = class)) + scale_x_continuous(limits = c(-5, 5))
ggplot(current_year, aes(x = temp_r)) + geom_density(aes(group = class, colour = class))

by_class = group_by(current_year, class)
class_summary = summarise(by_class,
                          count = n(),
                          rsquared_mean = mean(temp_r_squared),
                          rsquared_sd = sd(temp_r_squared),
                          rsquared_med = median(temp_r_squared),
                          slope_mean = mean(temp_slope),
                          slope_sd = sd(temp_slope),
                          slope_med = median(temp_slope), 
                          r_mean = mean(temp_r), 
                          r_sd = sd(temp_r), 
                          r_med = median(temp_r))

# Mass-temp relationships for species with large latitude or temp range
by_species = group_by(all_individuals, clean_genus_species)
species_summary = summarise(by_species, 
                            lat_min = min(decimallatitude), 
                            lat_max = max(decimallatitude), 
                            temp_min = min(july_temps), 
                            temp_max = max(july_temps))

current_year = merge(current_year, species_summary, by.x = "genus_species", by.y = "clean_genus_species")
current_year$lat_diff = current_year$lat_max - current_year$lat_min
current_year$temp_diff = current_year$temp_max - current_year$temp_min
large_lat_CY = current_year[current_year$lat_diff > 41.1,] #top quartile of lat range
large_temp_CY = current_year[current_year$temp_diff > 23.60,]

plot(density(current_year$temp_r_squared))
lines(density(large_lat_CY$temp_r_squared), col = "red")
plot(density(current_year$temp_slope, from = -100, to = 100))
lines(density(large_lat_CY$temp_slope, from = -100, to = 100), col = "red")
abline(v = 0)
plot(large_lat_CY$temp_r_squared, large_lat_CY$temp_slope)
plot(density(current_year$temp_r))
lines(density(large_lat_CY$temp_r), col = "red")

plot(density(current_year$temp_r_squared))
lines(density(large_temp_CY$temp_r_squared), col = "red")
plot(density(current_year$temp_slope, from = -100, to = 100))
lines(density(large_temp_CY$temp_slope, from = -100, to = 100), col = "red")
abline(v = 0)
plot(large_temp_CY$temp_r_squared, large_temp_CY$temp_slope)
plot(density(current_year$temp_r))
lines(density(large_temp_CY$temp_r), col = "red")

# Mass-latitude relationships
par(mfrow = c(1, 3))
lr = density(current_year$lat_r_squared)
plot(lr, xlim = c(0, 1), xlab = "r^2", ylab = "", main = "Each species' r^2 dist from collection year temp")
polygon(lr, col = "chartreuse3", border = "chartreuse3")
abline(v = mean(current_year$lat_r_squared), lty = 3)
abline(v = median(current_year$lat_r_squared), lty = 2)
legend("top", c("mean", "median"), lty = c(3, 2), bty = "n")

ls = density(current_year$lat_slope, from = -10, to = 10)
plot(ls, xlab = "slope", ylab = "", main ="Each species' slope dist from collection year temp")
polygon(ls, col = "cornflowerblue", border = "cornflowerblue")
#abline(v = 0, col = "gray")
abline(v = mean(current_year$lat_slope), lty = 3)
abline(v = median(current_year$lat_slope), lty = 2)

cs = density(current_year$lat_r)
plot(cs, xlim = c(-1, 1), xlab = "r", ylab = "", main = "Each species' r dist from collection year temp")
polygon(cs, col = "red", border = "red")
abline(v = c(0, -1, 1), col = "gray")
abline(v = mean(current_year$lat_r), lty = 3)
abline(v = median(current_year$lat_r))

# Spatial distribution of individuals
all_individuals$map_long = ifelse(all_individuals$longitude > 180, all_individuals$longitude - 360, all_individuals$longitude)
unique_coords = unique(all_individuals[c("map_long", "decimallatitude")])
library(rworldmap)
map = getMap(resolution = "low")
plot(map)
points(unique_coords$map_long, unique_coords$decimallatitude, pch = 20, cex = 0.1, col = "red")
