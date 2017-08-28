library(plyr)
library(dplyr)
library(ggplot2)
library(cowplot)

theme_set(theme_bw())

species_stats = read.csv("results_outliers/species_stats.csv")
individuals_data = read.csv("results_outliers/stats_data.csv")
species_stats = species_stats[species_stats$class != "Amphibia" & species_stats$class != "Reptilia",]
species_stats$class = factor(species_stats$class)
individuals_data = individuals_data[individuals_data$class != "Amphibia" & individuals_data$class != "Reptilia",]
individuals_data$class = factor(individuals_data$class)

species_summary = individuals_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    temp_range = max(temperature) - min(temperature), 
    mass_range = max(massing) - min(massing), 
    mass_mean = mean(massing),
    lat_mean = mean(decimallatitude)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

# FIRST FIGURE
species_list = c("Martes pennanti", "Tamias quadrivittatus", "Synaptomys cooperi")
individuals_data$map_long = ifelse(individuals_data$longitude > 180, individuals_data$longitude - 360, individuals_data$longitude)
locations = unique(individuals_data[c("map_long", "decimallatitude", "clean_genus_species")])
locations$Species = ifelse(locations$clean_genus_species == species_list[1], species_list[1], 
                           ifelse(locations$clean_genus_species == species_list[2], species_list[2], 
                                  ifelse(locations$clean_genus_species == species_list[3], species_list[3], "All")))
locations$Species = factor(locations$Species, levels = c("All", species_list[1], species_list[2], species_list[3]))
locations = locations[order(locations$Species),]

plot_locations = ggplot(data = locations, aes(x = map_long, y = decimallatitude)) +
  borders("world", colour = "grey70") +
  geom_point(aes(color = Species, shape = Species, size = Species)) +
  scale_shape_manual(values = c(20, 20, 20, 20)) +
  scale_color_manual(values = c("black", "steelblue1", "yellow", "red")) +
  scale_size_manual(values = c(0.2, 1, 1, 1)) +
  theme(legend.position = c(0.1, 0.2), 
        legend.key = element_rect(colour = NA),
        axis.line = element_blank(), 
        axis.text.x = element_blank(), 
        axis.text.y = element_blank(),
        axis.ticks = element_blank(), 
        axis.title.x = element_blank(), 
        axis.title.y = element_blank(),  
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.border = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size = 3)))

species_scatterplot = function(species){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  lr_mass = lm(massing ~ temperature, data = species_data)
  lr_summary = summary(lr_mass)
  r = round(ifelse(lr_summary$coefficients[2] < 0, -sqrt(lr_summary$r.squared), sqrt(lr_summary$r.squared)), 3)
  pval = format(lr_summary$coefficients[2, 4], digits = 3)
  r_string = paste("r =", r)
  p_string = paste("p =", pval)
  ggplot(species_data, aes(temperature, massing)) +
          geom_point() +
          geom_smooth(method = "lm", se = FALSE) +
          labs(x = expression("Mean annual temperature " (degree~C)), y = "Mass (g)") +
          theme(panel.grid.major = element_blank(), 
                panel.grid.minor = element_blank()) +
          annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = r_string) +
          annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.2, vjust = 3.25, label = p_string)
}

all_species = lapply(species_list, species_scatterplot)
plot_examples = plot_grid(plotlist = all_species, nrow = 1)

plot_fig1 = ggdraw() +
  draw_plot(plot_locations, 0, 0.25, 1, 0.75) +
  draw_plot(plot_examples, 0, 0, 1, 0.3)

# SECOND FIGURE
species_stats$temp_pvalue_adjust = p.adjust(species_stats$temp_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(temp_stat_sig = ifelse(temp_pvalue_adjust < 0.05 & temp_slope < 0, "neg", 
                          ifelse(temp_pvalue_adjust < 0.05 & temp_slope > 0, "pos", "not")))

species_stats$temp_stat_sig = factor(species_stats$temp_stat_sig, levels = c("not", "neg", "pos"))
plot_stats = ggplot(species_stats, aes(temp_r, fill = temp_stat_sig)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5)), 
                    labels = c("Not", "Negative", "Positive")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 110)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.15, 0.6), y = c(12, 110, 9), label = c("20%", "71%", "9%"))

species_stats$class = factor(species_stats$class, levels = c("Mammalia", "Aves"))
plot_class = ggplot(species_stats, aes(temp_r, fill = class)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", "blue")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 110)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_hists = ggdraw() +
  draw_plot(plot_stats, 0, 0, 0.5, 1) +
  draw_plot(plot_class, 0.5, 0, 0.5, 1)

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

plot_mass = ggplot(species_stats, aes(x = mass_range, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of masses (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_size = ggplot(species_stats, aes(x = mass_mean, y = temp_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Mean mass (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_lat = ggplot(species_stats, aes(x = abs(lat_mean), y = temp_r)) + 
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = expression("Absolute mean latitude " (degree)), y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_5 = plot_grid(plot_individuals, plot_temp, plot_mass, plot_size, plot_lat)
-ggsave("results_lifestagefilter/figure4.jpg", width = 9.5, height = 6)

ggdraw() +
  draw_plot(plot_fig1, 0, 0.57, 1, 0.43) +
  draw_plot(plot_hists, 0, 0.25, 1, 0.32) +
  draw_plot(plot_5, 0, 0, 0.8, 0.25) + 
  draw_plot_label("A", 0, 1) +
  draw_plot_label("B", 0, 0.57) +
  draw_plot_label("C", 0, 0.25)
ggsave("results_outliers/fig_outliers.jpg", width = 6, height = 12)
