library(plyr)
library(dplyr)
library(ggplot2)
library(cowplot)

theme_set(theme_bw())

species_stats = read.csv("results/species_stats.csv")
individuals_data = read.csv("results/stats_data.csv")

species_summary = individuals_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    lat_range = max(decimallatitude) - min(decimallatitude), 
    mass_range = max(mass) - min(mass), 
    mass_mean = mean(mass)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

species_stats_TL = read.csv("temp_stats.csv")
species_stats_TL$r = ifelse(species_stats_TL$slope < 0, -sqrt(species_stats_TL$r_squared), sqrt(species_stats_TL$r_squared))

# FIRST FIGURE
species_scatterplot = function(species){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  print(species_stats[species_stats$genus_species == species,])
  species_data$rel_mass = species_data$mass / mean(species_data$mass)
  lr_mass = lm(mass ~ abs(decimallatitude), data = species_data)
  lr_summary = summary(lr_mass)
  r2 = round(lr_summary$r.squared, 3)
  pval = format(round(lr_summary$coefficients[2, 4], 4), scientific = FALSE)
  r_string = paste("R^{2} == ", r2)
  p_string = paste("p =", pval)
  lr_relmass = lm(rel_mass ~ abs(decimallatitude), data = species_data)
  print(summary(lr_relmass))
  ggplot(species_data, aes(abs(decimallatitude), mass)) +
    geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    labs(x = "Absolute latitude", y = "Mass (g)") +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = r_string, parse = TRUE) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 4, label = p_string, parse = FALSE)
}

species_list = c("Setophaga palmarum", "Tangara vassorii", "Quelea quelea")
all_species = lapply(species_list, species_scatterplot)
plot_grid(plotlist = all_species, nrow = 1, labels = c("A", "B", "C"))

# SECOND FIGURE
species_stats$lat_pvalue_adjust = p.adjust(species_stats$lat_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(lat_stat_sig = ifelse(lat_pvalue_adjust < 0.05 & lat_slope < 0, "neg", 
                           ifelse(lat_pvalue_adjust < 0.05 & lat_slope > 0, "pos", "not")))

species_stats$lat_stat_sig = factor(species_stats$lat_stat_sig, levels = c("neg", "pos", "not"))
plot_stats = ggplot(species_stats, aes(lat_r, fill = lat_stat_sig)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c(rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5), "white"), 
                    labels = c("Negative", "Positive", "Not")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.11, 0.6), y = c(15, 105, 28), label = c("12%", "69%", "19%"))

species_stats$class_combine = as.character(species_stats$class)
species_stats$class_combine[species_stats$class_combine == "Amphibia" | species_stats$class_combine == "Reptilia"] <- "Reptilia & Amphibia"
plot_class = ggplot(species_stats, aes(lat_r, fill = class_combine)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c("blue", "white", "red")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_stats, plot_class, nrow = 2, labels = c("A", "B"))

# THIRD FIGURE
plot_individuals = ggplot(species_stats, aes(x = individuals, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Number of individuals", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_temp = ggplot(species_stats, aes(x = lat_range, y = lat_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of latitudes", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass = ggplot(species_stats, aes(x = mass_mean, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Mean mass (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass2 = ggplot(species_stats, aes(x = mass_range, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of masses (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_individuals, plot_temp, plot_mass, plot_mass2, labels = c("A", "B", "C", "D"))

# FOURTH FIGURE
ggplot(species_stats_TL, aes(x = past_year, y = r)) +
  geom_point(size = 0.2, color = "chartreuse3") + 
  stat_summary(aes(y = r, group = 1), fun.y = mean, geom = "point", group = 1, size = 0.5) +
  coord_cartesian(ylim = c(-1, 1)) +
  labs(x = "Past year", y = "r") +
  theme(panel.grid.major = element_blank(),
         panel.grid.minor = element_blank())
