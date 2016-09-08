library(dplyr)
library(ggplot2)

species_stats = read.csv("results/species_stats.csv")
individuals_data = read.csv("results/stats_data.csv")

species_summary = individuals_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    lat_range = max(decimallatitude) - min(decimallatitude), 
    temp_range = max(decimallatitude) - min(decimallatitude), 
    mass_range = max(mass) - min(mass), 
    mass_mean = mean(mass)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

species_stats_TL = read.csv("temp_stats.csv")
species_stats_TL$r = ifelse(species_stats_TL$slope < 0, -sqrt(species_stats_TL$r_squared), sqrt(species_stats_TL$r_squared))
species_stats_TL$past_year = as.factor(species_stats_TL$past_year)

# 1: density plot of r values for all species' temp-mass relationships
ggplot(species_stats, aes(temp_r)) + 
  geom_density(fill = "blue", alpha = 0.3) + 
  geom_vline(xintercept = 0) +
  xlim(-1, 1)

# 2: overlaid density plots for each class of r values for all species' temp-mass relationships
ggplot(species_stats, aes(temp_r, colour = class)) +
  geom_density() + 
  xlim(-1, 1)

class_summary = species_stats %>%
  group_by(class) %>%
  summarise(
    number_species = n(), 
    r_mean = mean(temp_r), 
    r_sd = sd(temp_r), 
    r_med = median(temp_r)
  )

# 3: overlaid density plots for select past year temps of r values for all species' temp-mass relationships
ggplot(subset(species_stats_TL, past_year %in% c("0", "10", "25", "50", "80"))) +
  geom_density(aes(r, group = past_year, colour = past_year)) +
  geom_vline(xintercept = 0) +
  xlim(-1, 1)

# 4: scatterplot of each species' temp range and r
ggplot(species_stats, aes(x = temp_range, y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 5: scatterplot of each species' log-transformed number of individual and r
ggplot(species_stats, aes(x = log(individuals), y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 6: scatterplot of each species' log-transformed mass range and r
ggplot(species_stats, aes(x = log(mass_range), y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 7: scatterplot of each species' latitude range and r
ggplot(species_stats, aes(x = lat_range, y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 8: plot comparing species' log-transformed average mass to r
ggplot(species_stats, aes(x = log(mass_mean), y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 9: examples of 3 species' temp-mass relationship plots
species_list = c("Dryocopus lineatus", "Sitta canadensis", "Corvus brachyrhynchos")
for(species in species_list){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  species_data$rel_mass = species_data$mass / mean(species_data$mass)
  lr_mass = lm(mass ~ july_temps, data = species_data)
  lr_summary = summary(lr_mass)
  r2 = round(lr_summary$r.squared, 3)
  pval = round(lr_summary$coefficients[2,4], 4)
  coefficients_string = paste("r2 =", r2, ";", "p =", pval)
  print(ggplot(species_data, aes(july_temps, mass)) +
          geom_point() +
          geom_smooth(method = "lm", se = FALSE) +
          annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = coefficients_string) +
          labs(title = species)
  )
  lr_relmass = lm(rel_mass ~ july_temps, data = species_data)
  print(summary(lr_relmass))
}

# 10: stats plot (bar chart or multiple comparison plot)

# 11: density plot of r values for all species' lat-mass relationships
ggplot(species_stats, aes(lat_r)) + 
  geom_density(fill = "blue", alpha = 0.3) + 
  geom_vline(xintercept = 0) +
  xlim(-1, 1)

# 12: overlaid density plots for each class of r values for all species' lat-mass relationships
ggplot(species_stats, aes(lat_r, colour = class)) +
  geom_density() + 
  xlim(-1, 1)

