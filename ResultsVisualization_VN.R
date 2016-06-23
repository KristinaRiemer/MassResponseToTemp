all_stats = read.csv("species_stats.csv")

# All lags across all species
plot(all_stats$r_squared, all_stats$slope, main = "all lags")
abline(v = mean(all_stats$r_squared), h = mean(all_stats$slope))
plot(density(all_stats$r_squared), main = "all lags r2")
plot(density(all_stats$slope), main = "all lags slope")

# Current year for all species
current_year = all_stats[all_stats$past_year == 0,]
plot(current_year$r_squared, current_year$slope, main = "zero lag")
abline(v = mean(current_year$r_squared), h = mean(current_year$slope))
plot(density(current_year$r_squared), main = "zero lag r2")
plot(density(current_year$slope), main = "zero lag slope")

# Comparing current year to all lags
mean(all_stats$r_squared)
mean(current_year$r_squared)
mean(all_stats$slope)
mean(current_year$slope)

# Looking at stats by lag year
plot(all_stats$past_year, all_stats$r_squared, pch = '.')
plot(all_stats$past_year, all_stats$slope, pch = '.')


library(dplyr)
by_lag = group_by(all_stats, past_year)
lags_summary = summarise(by_lag, 
          count = n(), 
          rsquared_mean = mean(r_squared), 
          rsquared_sd = sd(r_squared), 
          slope_mean = mean(slope), 
          slope_sd = sd(slope))

plot(lags_summary$past_year, lags_summary$rsquared_mean, pch = 19)
arrows(lags_summary$past_year, lags_summary$rsquared_mean - lags_summary$rsquared_sd, lags_summary$past_year, lags_summary$rsquared_mean + lags_summary$rsquared_sd, length = 0, angle = 90)

plot(lags_summary$past_year, lags_summary$slope_mean, ylim = range(c(lags_summary$slope_mean - lags_summary$slope_sd,lags_summary$slope_mean + lags_summary$slope_sd)), pch = 19)
arrows(lags_summary$past_year, lags_summary$slope_mean - lags_summary$slope_sd, lags_summary$past_year, lags_summary$slope_mean + lags_summary$slope_sd, length = 0, angle = 90)

# Looking at by number of individuals per each species
num_individuals = read.csv("num_individuals.csv")
all_stats = merge(x = all_stats, y = num_individuals, by = "genus_species", all.x = TRUE)
all_stats$X.x = NULL
all_stats$X.y = NULL

many_individuals = all_stats[all_stats$individuals >= median(all_stats$individuals),]
few_individuals = all_stats[all_stats$individuals < median(all_stats$individuals),]

# Many vs few individuals current year
current_year_many = many_individuals[many_individuals$past_year == 0,]
current_year_few = few_individuals[few_individuals$past_year == 0,]

plot(density(current_year_many$r_squared))
lines(density(current_year_few$r_squared))

plot(density(current_year_many$slope))
lines(density(current_year_few$slope))

plot(current_year_many$r_squared, current_year_many$slope, ylim = c(-100, 100))
abline(v = mean(current_year_many$r_squared), h = mean(current_year_many$slope))
points(current_year_few$r_squared, current_year_few$slope, col = rgb(0, 0, 0, alpha = 0.2))
abline(v = mean(current_year_few$r_squared), h = mean(current_year_few$slope), col = rgb(0, 0, 0, alpha = 0.2))

# TODO: 
# Look at mass-latitude relationships
# Split up by taxonomic group
# Removing temporal: species with only 5 years range (like previous Bergmann studies)
# Removing spatial: lots of points across time with short spatial range
# Plot # individuals vs r2/r
# Look at species with really high slopes
# Something about spatial distribution? 
