library(plyr)
library(dplyr)
library(ggplot2)
library(cowplot)
library(stringr)
library(DescTools)

theme_set(theme_bw())

species_stats = read.csv("results/species_stats.csv")
individuals_data = read.csv("results/stats_data.csv")

species_stats = species_stats[species_stats$class == "Mammalia" | species_stats$class == "Aves",]
individuals_data = individuals_data[individuals_data$class == "Mammalia" | individuals_data$class == "Aves",]

species_summary = individuals_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    temp_range = max(temperature) - min(temperature), 
    mass_range = max(massing) - min(massing), 
    mass_mean = mean(massing),
    lat_mean = mean(decimallatitude), 
    year_range = max(year) - min(year), 
    lat_range = max(decimallatitude) - min(decimallatitude)
  )
species_stats = merge(species_stats, species_summary, all.x = TRUE, by.x = "genus_species", by.y = "clean_genus_species")
species_stats = species_stats[species_stats$year_range >= 20 & species_stats$lat_range >= 5,]
species_stats$genus_species = factor(species_stats$genus_species)
individuals_data = individuals_data[individuals_data$clean_genus_species %in% species_stats$genus_species,]
individuals_data$clean_genus_species = factor(individuals_data$clean_genus_species)

species_stats_TL = read.csv("results_TL/species_stats.csv")
species_stats_TL = species_stats_TL[species_stats_TL$class == "Mammalia" | species_stats_TL$class == "Aves",]
species_stats_TL = species_stats_TL[species_stats_TL$genus_species %in% species_stats$genus_species,]

# FIRST FIGURE
species_list = c("Martes pennanti", "Tamias quadrivittatus", "Synaptomys cooperi")
point_colors = c("steelblue1", "yellow", "red")
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

species_scatterplot = function(species, point_color){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  lr_mass = lm(massing ~ temperature, data = species_data)
  lr_summary = summary(lr_mass)
  r = round(ifelse(lr_summary$coefficients[2] < 0, -sqrt(lr_summary$r.squared), sqrt(lr_summary$r.squared)), 3)
  pval = format(lr_summary$coefficients[2, 4], digits = 3)
  r_string = paste("r =", r)
  p_string = paste("p =", pval)
  ggplot(species_data, aes(temperature, massing)) +
    geom_point(color = point_color) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(x = expression("Mean annual temperature " (degree~C)), y = "Mass (g)") +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.25, vjust = 1.5, label = r_string) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = -0.2, vjust = 3.25, label = p_string)
}

if(length(unique(individuals_data$clean_genus_species)) < 900){
  ggdraw() +
    draw_plot(plot_locations)
  ggsave("figures/figure1.jpg", width = 10, height = 6)
} else {
  all_species = mapply(species_scatterplot, species_list, point_colors, SIMPLIFY = FALSE)
  plot_examples = plot_grid(plotlist = all_species, nrow = 1, labels = c("B", "C", "D"))
  ggdraw() +
    draw_plot(plot_locations, 0, 0.25, 1, 0.75) +
    draw_plot(plot_examples, 0, 0, 1, 0.3) +
    draw_plot_label("A", 0, 1)
  ggsave("figures/figure1.jpg", width = 10, height = 8)
}

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
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.15, 0.6), y = c(12, 129, 9), label = c("14%", "79%", "7%"))

species_stats$class = factor(species_stats$class, levels = c("Mammalia", "Aves"))
plot_class = ggplot(species_stats, aes(temp_r, fill = class)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", "blue")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

ggdraw() +
  draw_plot(plot_stats, 0, 0, 0.5, 1) +
  draw_plot(plot_class, 0.5, 0, 0.5, 1) +
  draw_plot_label(c("A", "B"), c(0, 0.5), c(1, 1))
ggsave("figures/figure2.jpg", width = 10, height = 6)

# THIRD FIGURE
orders_table = table(species_stats$order)
orders_df = species_stats[species_stats$order %in% names(orders_table[orders_table > 10]),]

orders_df$order = factor(orders_df$order, levels = c("Carnivora", "Chiroptera", "Rodentia", "Soricomorpha", "Anseriformes", "Apodiformes", "Charadriiformes", "Columbiformes", "Galliformes", "Passeriformes", "Piciformes", "Strigiformes"))
plot_order = ggplot(orders_df, aes(temp_r, fill = class)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  coord_cartesian(xlim = c(-1, 1)) +
  scale_fill_manual(values = c("gray40", "white")) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        strip.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  facet_wrap(~ order, scales = "free_y")

if(nrow(orders_df) > 0){
  ggsave("figures/figure3.jpg", plot = plot_order, width = 10, height = 7)
}

# FOURTH FIGURE
past_year_hist = function(year){
  ggplot(subset(species_stats_TL, past_year %in% year)) +
    geom_histogram(aes(r), breaks = seq(-1, 1, by = 0.05), fill = "white", col = "black", size = 0.2) +
    coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
    labs(x = "r", y = "Number of species") +
    geom_vline(xintercept = 0, size = 1) +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +
    annotate("text", x= 0.75, y = 75, label = paste(year, "years prior"))
}

past_year_values = c("0", "25", "50")
all_hists = lapply(past_year_values, past_year_hist)
plot_grid(plotlist = all_hists, ncol = 1, labels = c("A", "B", "C"))
ggsave("figures/figure4.jpg", width = 4, height = 12)

# FIFTH FIGURE
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

plot_grid(plot_individuals, plot_temp, plot_mass, plot_size, plot_lat, labels = c("A", "B", "C", "D", "E"))
ggsave("figures/figure5.jpg", width = 9.5, height = 6)

# DATA SOURCE CITATIONS

# Reference
citations = as.character(unique(individuals_data$citation))
for(citation in citations){
  cite = strsplit(citation, "[.]")
  cite[[1]][1] = paste("", cite[[1]][1])
  cite = cite[[1]][c(2, 1, 3, 4, 5, 6, 7, 8)]
  cite = cite[!is.na(cite)]
  cite = paste(cite, collapse = ".")
  cite = str_trim(cite, side = "left")
  cite = str_sub(cite, 1, str_length(cite) - 1)
  cite = paste(cite, ", accessed on 2017-10-19)", sep = "")
  print(cat(noquote(cite)))
}

# Inline
citations_together = c()
for(citation in citations){
  cite = strsplit(citation, "[.]")
  cite1 = cite[[1]][2]
  cite = unlist(cite)
  cite2 = cite[length(cite)]
  cite2 = str_sub(cite2, -11, -8)
  cite = paste(cite1, cite2, sep = ", ")
  print(cite)
  citations_together = paste(citations_together, cite, sep = ";")
}
print(citations_together)
