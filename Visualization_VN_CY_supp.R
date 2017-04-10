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
    temp_range = max(temperature) - min(temperature), 
    mass_range = max(massing) - min(massing), 
    mass_mean = mean(massing),
    lat_mean = mean(decimallatitude)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")

species_stats_TL = read.csv("results_TL/species_stats.csv")
species_stats_TL = species_stats_TL[species_stats_TL$class == "Mammalia" | species_stats_TL$class == "Aves",]

# FIRST FIGURE
species_list = c("Martes pennanti", "Spizella arborea", "Synaptomys cooperi")
species_scatterplot = function(species){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  lr_mass = lm(massing ~ abs(decimallatitude), data = species_data)
  lr_summary = summary(lr_mass)
  r = round(ifelse(lr_summary$coefficients[2] < 0, -sqrt(lr_summary$r.squared), sqrt(lr_summary$r.squared)), 3)
  pval = lr_summary$coefficients[2, 4]
  r_string = paste("r =", r)
  p_string = paste("p =", pval)
  ggplot(species_data, aes(abs(decimallatitude), massing)) +
    geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    labs(x = "Absolute latitude", y = "Mass (g)") +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = r_string) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 4, label = p_string)
}

if(length(unique(individuals_data$clean_genus_species)) > 900){
  all_species = lapply(species_list, species_scatterplot)
  plot_grid(plotlist = all_species, nrow = 1, labels = c("A", "B", "C"))
  ggsave("figures/figure1_supp.jpg", width = 10, height = 3)
}

# SECOND FIGURE
species_stats$lat_pvalue_adjust = p.adjust(species_stats$lat_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(lat_stat_sig = ifelse(lat_pvalue_adjust < 0.05 & lat_slope < 0, "neg", 
                               ifelse(lat_pvalue_adjust < 0.05 & lat_slope > 0, "pos", "not")))

species_stats$lat_stat_sig = factor(species_stats$lat_stat_sig, levels = c("neg", "pos", "not"))
plot_stats = ggplot(species_stats, aes(lat_r, fill = lat_stat_sig)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c(rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5), "white"), 
                    labels = c("Negative", "Positive", "Not")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.11, 0.6), y = c(15, 105, 28), label = c("10%", "70%", "20%"))

species_stats$class_combine = as.character(species_stats$class)
species_stats$class_combine[species_stats$class_combine == "Amphibia" | species_stats$class_combine == "Reptilia"] <- "Reptilia & Amphibia"
plot_class = ggplot(species_stats, aes(lat_r, fill = class_combine)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("blue", "white", "red")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

order_plot_df = species_stats %>%
  group_by(order) %>%
  mutate(number_species = n())
order_plot_df$order = factor(order_plot_df$order, levels = unique(order_plot_df$order[order(order_plot_df$number_species, decreasing = TRUE)]))
order_plot_df$order = mapvalues(order_plot_df$order, from = "", to = "Unknown")
order_colors = rainbow(35, s = 1, v = 0.9)[sample(1:35, 35)]
plot_order = ggplot(order_plot_df, aes(lat_r, fill = order)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = order_colors) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Order: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        legend.key.size = unit(0.2, "cm"),
        legend.text = element_text(size = 6.5),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

ggdraw() +
  draw_plot(plot_stats, 0, 0, 0.5, 1) +
  draw_plot(plot_class, 0.5, 0.5, 0.5, 0.5) +
  draw_plot(plot_order, 0.5, 0, 0.5, 0.5) +
  draw_plot_label(c("A", "B", "C"), c(0, 0.5, 0.5), c(1, 1, 0.5))
ggsave("figures/figure2_supp.jpg", width = 10, height = 10)

# THIRD FIGURE
#correlation coefficient for temperature-mass, not latitude-mass
ggplot(species_stats_TL, aes(x = past_year, y = r)) +
  geom_point(size = 0.2, color = "chartreuse3") + 
  stat_summary(aes(y = r, group = 1), fun.y = mean, geom = "point", group = 1, size = 0.5) +
  coord_cartesian(ylim = c(-1, 1)) +
  labs(x = "Past year", y = "r") +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

ggsave("figures/figure3_supp.jpg", width = 4, height = 3)

# FOURTH FIGURE
plot_individuals = ggplot(species_stats, aes(x = individuals, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Number of individuals", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_temp = ggplot(species_stats, aes(x = temp_range, y = lat_r)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of temperatures", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass = ggplot(species_stats, aes(x = mass_range, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of masses (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_size = ggplot(species_stats, aes(x = mass_mean, y = lat_r)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Mean mass (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_lat = ggplot(species_stats, aes(x = abs(lat_mean), y = lat_r)) + 
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = expression("Absolute mean latitude " (degree)), y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_grid(plot_individuals, plot_temp, plot_mass, plot_size, plot_lat, labels = c("A", "B", "C", "D", "E"))
ggsave("figures/figure4_supp.jpg", width = 9.5, height = 6)

# FIFTH FIGURE
ectos_df = species_stats[species_stats$class_combine == "Reptilia & Amphibia",]
plot_ectos = ggplot(ectos_df, aes(temp_r)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.1), col = "black", size = 0.2) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 5)) +
  labs(x = "r", y = "Number of species") +
  geom_vline(xintercept = 0, size = 1) +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())
ggsave("figures/figure5_supp.jpg", plot = plot_ectos, width = 5, height = 8)

# SIXTH FIGURE
first = 1
last = 96
full_sp_list = c()
for(i in 1:10){
  sp_list = unique(species_stats$genus_species)[first:last]
  if(!is.na(sp_list[96])){
    inds_df = individuals_data[individuals_data$clean_genus_species %in% sp_list,]
    inds_plot = ggplot(inds_df, aes(x = temperature, y = massing)) +
      geom_point(color = "gray48", size = 0.3) +
      facet_wrap(~clean_genus_species, scales = "free", ncol = 8) +
      geom_smooth(method = "lm", se = FALSE, color = "black") +
      labs(x = expression("Mean annual temperature " (degree~C)), y = "Mass (g)") +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            strip.text = element_blank(),
            strip.background = element_blank(),
            axis.text = element_text(size = 5))
    ggsave(filename = paste("figures/", first, ".jpg", sep = ""), plot = inds_plot, width = 7, height = 9.25)
    sp_list = noquote(paste(sp_list, collapse = ", "))
    full_sp_list = append(full_sp_list, sp_list)
    first = first + 96
    last = last + 96
  }
}

last_sp_list = unique(species_stats$genus_species)[961:967]
if(!is.na(last_sp_list[1])){
  last_inds = individuals_data[individuals_data$clean_genus_species %in% last_sp_list,]
  ggplot(last_inds, aes(x = temperature, y = massing)) +
    geom_point(color = "gray48", size = 0.3) +
    facet_wrap(~clean_genus_species, scales = "free", ncol = 8) +
    geom_smooth(method = "lm", se = FALSE, color = "black") +
    labs(x = expression("Mean annual temperature " (degree~C)), y = "Mass (g)") +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          strip.text = element_blank(),
          strip.background = element_blank(),
          axis.text = element_text(size = 5))
  ggsave("figures/961.jpg", width = 7, height = 1.25)
}
