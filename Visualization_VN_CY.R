library(plyr)
library(dplyr)
library(ggplot2)
library(cowplot)

species_stats = read.csv("results/species_stats.csv")
individuals_data = read.csv("results/stats_data.csv")

species_summary = individuals_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    #lat_range = max(decimallatitude) - min(decimallatitude), 
    temp_range = max(july_temps) - min(july_temps), 
    mass_range = max(mass) - min(mass), 
    mass_mean = mean(mass)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

species_stats_TL = read.csv("temp_stats.csv")
species_stats_TL$r = ifelse(species_stats_TL$slope < 0, -sqrt(species_stats_TL$r_squared), sqrt(species_stats_TL$r_squared))

# FIRST FIGURE
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

# SECOND FIGURE
species_stats$temp_pvalue_adjust = p.adjust(species_stats$temp_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(stat_sig = ifelse(temp_pvalue_adjust < 0.05 & temp_slope < 0, "neg", 
                          ifelse(temp_pvalue_adjust < 0.05 & temp_slope > 0, "pos", "not")))

species_stats$stat_sig = factor(species_stats$stat_sig, levels = c("neg", "pos", "not"))
plot_stats = ggplot(species_stats, aes(temp_r, fill = stat_sig)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c(rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5), "white"), 
                    labels = c("Negative", "Positive", "Not")) +
  coord_cartesian(xlim = c(-1, 1)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme_bw() +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.15, 0.6), y = c(12, 129, 9), label = c("14%", "79%", "7%"))

species_stats$class = factor(species_stats$class, levels = c("Aves", "Mammalia", "Reptilia", "Amphibia"))
plot_class = ggplot(species_stats, aes(temp_r, fill = class)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c("#C6DBEF", "white", "#6BAED6", "#084594")) +
  coord_cartesian(xlim = c(-1, 1)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme_bw() +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_stats, plot_class, nrow = 2, labels = c("A", "B"))

# THIRD FIGURE
# 3: overlaid density plots for select past year temps of r values for all species' temp-mass relationships
species_stats_TL$past_year = as.factor(species_stats_TL$past_year)
ggplot(subset(species_stats_TL, past_year %in% c("0", "10", "25", "50", "80"))) +
  geom_density(aes(r, group = past_year, colour = past_year)) +
  geom_vline(xintercept = 0) +
  xlim(-1, 1)

# FOURTH FIGURE
# 4: scatterplot of each species' temp range and r
ggplot(species_stats, aes(x = temp_range, y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 5: scatterplot of each species' log-transformed number of individual and r
ggplot(species_stats, aes(x = individuals, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 6: scatterplot of each species' log-transformed mass range and r
ggplot(species_stats, aes(x = mass_range, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# 8: plot comparing species' log-transformed average mass to r
ggplot(species_stats, aes(x = mass_mean, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1)

# SUPPLEMENTARY FIGURES
# 3.5: scatterplot for all past year temps against r value for all species
ggplot(species_stats_TL, aes(x = past_year, y = r)) +
  geom_point(size = 0.2, color = "chartreuse3") + 
  stat_summary(aes(y = r, group = 1), fun.y = mean, geom = "point", group = 1, size = 0.5)
