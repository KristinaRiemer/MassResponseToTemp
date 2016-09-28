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
    temp_range = max(july_temps) - min(july_temps), 
    mass_range = max(mass) - min(mass), 
    mass_mean = mean(mass)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

species_stats_TL = read.csv("temp_stats.csv")
species_stats_TL$r = ifelse(species_stats_TL$slope < 0, -sqrt(species_stats_TL$r_squared), sqrt(species_stats_TL$r_squared))

# FIRST FIGURE
species_scatterplot = function(species){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  species_data$rel_mass = species_data$mass / mean(species_data$mass)
  lr_mass = lm(mass ~ july_temps, data = species_data)
  lr_summary = summary(lr_mass)
  r2 = format(round(lr_summary$r.squared, 4), scientific = FALSE)
  pval = ifelse(lr_summary$coefficients[2, 4] > 0.000005, round(lr_summary$coefficients[2,4], 3), format(lr_summary$coefficients[2, 4], digits = 3))
  r_string = paste("R^{2} == ", r2)
  p_string = paste("p =", pval)
  lr_relmass = lm(rel_mass ~ july_temps, data = species_data)
  print(summary(lr_relmass))
  ggplot(species_data, aes(july_temps, mass)) +
          geom_point() +
          geom_smooth(method = "lm", se = FALSE) +
          labs(x = expression("Temperature " (degree~C)), y = "Mass (g)") +
          annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = r_string, parse = TRUE) +
          annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 4, label = p_string, parse = FALSE)
}

species_list = c("Dryocopus lineatus", "Sitta canadensis", "Corvus brachyrhynchos")
all_species = lapply(species_list, species_scatterplot)
plot_grid(plotlist = all_species, nrow = 1, labels = c("A", "B", "C"))

# SECOND FIGURE
species_stats$temp_pvalue_adjust = p.adjust(species_stats$temp_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(temp_stat_sig = ifelse(temp_pvalue_adjust < 0.05 & temp_slope < 0, "neg", 
                          ifelse(temp_pvalue_adjust < 0.05 & temp_slope > 0, "pos", "not")))

species_stats$temp_stat_sig = factor(species_stats$temp_stat_sig, levels = c("neg", "pos", "not"))
plot_stats = ggplot(species_stats, aes(temp_r, fill = temp_stat_sig)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c(rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5), "white"), 
                    labels = c("Negative", "Positive", "Not")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 150)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.15, 0.6), y = c(12, 129, 9), label = c("14%", "79%", "7%"))

species_stats$class_combine = as.character(species_stats$class)
species_stats$class_combine[species_stats$class_combine == "Amphibia" | species_stats$class_combine == "Reptilia"] <- "Reptilia & Amphibia"
plot_class = ggplot(species_stats, aes(temp_r, fill = class_combine)) +
  geom_histogram(bins = 31, col = "black", size = 0.2) +
  scale_fill_manual(values = c("blue", "white", "red")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 150)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_stats, plot_class, nrow = 2, labels = c("A", "B"))

# THIRD FIGURE
past_year_hist = function(year){
  ggplot(subset(species_stats_TL, past_year %in% year)) +
  geom_histogram(aes(r), bins = 31, fill = "white", col = "black", size = 0.2) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 150)) +
  labs(x = "r", y = "Number of species") +
  geom_vline(xintercept = 0, size = 1) +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x= 0.75, y = 75, label = paste(year, "years prior"))
}

past_year_values = c("0", "25", "50")
all_hists = lapply(past_year_values, past_year_hist)
plot_grid(plotlist = all_hists, ncol = 1, labels = c("A", "B", "C"))

# FOURTH FIGURE
plot_individuals = ggplot(species_stats, aes(x = individuals, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Number of individuals", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_temp = ggplot(species_stats, aes(x = temp_range, y = temp_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = expression("Range of temperatures " (degree~C)), y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass = ggplot(species_stats, aes(x = mass_mean, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Mean mass (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass2 = ggplot(species_stats, aes(x = mass_range, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of masses (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_individuals, plot_temp, plot_mass, plot_mass2, labels = c("A", "B", "C", "D"))
