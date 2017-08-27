library(plyr)
library(dplyr)
library(ggplot2)
library(cowplot)
library(XLConnect)
theme_set(theme_bw())

species_stats = read.csv("results/species_stats.csv")
individuals_data = read.csv("results/stats_data.csv")

species_stats = species_stats[species_stats$class == "Mammalia" | species_stats$class == "Aves",]
species_stats$class = factor(species_stats$class)
individuals_data = individuals_data[individuals_data$class == "Mammalia" | individuals_data$class == "Aves",]
individuals_data$class = factor(individuals_data$class)
individuals_data$clean_genus_species = factor(individuals_data$clean_genus_species)

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

eol_df = readWorksheetFromFile("MigStatus.xlsx", sheet = "ZZTblReviewAttributes")

# FIRST FIGURE
species_list = c("Martes pennanti", "Tamias quadrivittatus", "Synaptomys cooperi")
species_scatterplot = function(species){
  species_data = individuals_data[individuals_data$clean_genus_species == species,]
  lr_mass = lm(massing ~ abs(decimallatitude), data = species_data)
  lr_summary = summary(lr_mass)
  r = round(ifelse(lr_summary$coefficients[2] < 0, -sqrt(lr_summary$r.squared), sqrt(lr_summary$r.squared)), 3)
  pval = lr_summary$coefficients[2, 4]
  r_string = paste("r =", -r)
  p_string = paste("p =", pval)
  ggplot(species_data, aes(abs(decimallatitude), massing)) +
    geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    labs(x = "Absolute latitude", y = "Mass (g)") +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = 2, vjust = 1.5, label = r_string) +
    annotate(geom = "text", x = -Inf, y = Inf, hjust = 0.6, vjust = 4, label = p_string) +
    scale_x_reverse()
}

if(length(unique(individuals_data$clean_genus_species)) > 900){
  all_species = lapply(species_list, species_scatterplot)
  plot_species = plot_grid(plotlist = all_species, nrow = 1)
}

# SECOND FIGURE
species_stats$lat_pvalue_adjust = p.adjust(species_stats$lat_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(lat_stat_sig = ifelse(lat_pvalue_adjust < 0.05 & lat_slope < 0, "pos", 
                               ifelse(lat_pvalue_adjust < 0.05 & lat_slope > 0, "neg", "not")))
species_stats$lat_r_flipped = -species_stats$lat_r

species_stats$lat_stat_sig = factor(species_stats$lat_stat_sig, levels = c("not", "pos", "neg"))
plot_stats = ggplot(species_stats, aes(lat_r_flipped, fill = lat_stat_sig)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", rgb(0, 1, 0, 0.5), rgb(0, 0, 1, 0.5)), 
                    labels = c("Not", "Positive", "Negative")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  annotate("text", x = c(-0.75, -0.11, 0.6), y = c(15, 105, 28), label = c("19%", "71%", "10%"))

species_stats$class = factor(species_stats$class, levels = c("Mammalia", "Aves"))
plot_class = ggplot(species_stats, aes(lat_r_flipped, fill = class)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", "blue")) +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 130)) +
  labs(x = "r", y = "Number of species", fill = "Class: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top", 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

order_plot_df = species_stats %>%
  group_by(order) %>%
  mutate(number_species = n())
order_plot_df$order = factor(order_plot_df$order, levels = unique(order_plot_df$order[order(order_plot_df$number_species)]))
order_plot_df$order = mapvalues(order_plot_df$order, from = "", to = "Unknown")
order_colors = rainbow(35, s = 1, v = 0.9)[sample(1:35, 35)]
plot_order = ggplot(order_plot_df, aes(lat_r_flipped, fill = order)) +
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

plot_latitude = ggdraw() +
  draw_plot(plot_stats, 0, 0, 0.5, 1) +
  draw_plot(plot_class, 0.5, 0.5, 0.5, 0.5) +
  draw_plot(plot_order, 0.5, 0, 0.5, 0.5)

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
plot_individuals = ggplot(species_stats, aes(x = individuals, y = lat_r_flipped)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Number of individuals", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_temp = ggplot(species_stats, aes(x = temp_range, y = lat_r_flipped)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of temperatures", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_mass = ggplot(species_stats, aes(x = mass_range, y = lat_r_flipped)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Range of masses (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_size = ggplot(species_stats, aes(x = mass_mean, y = lat_r_flipped)) +
  geom_point() +
  scale_x_continuous(trans = "log10") +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = "Mean mass (g)", y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_lat = ggplot(species_stats, aes(x = abs(lat_mean), y = lat_r_flipped)) + 
  geom_point() +
  geom_hline(yintercept = 0) +
  ylim(-1, 1) +
  labs(x = expression("Absolute mean latitude " (degree)), y = "r") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())

plot_r = plot_grid(plot_individuals, plot_temp, plot_mass, plot_size, plot_lat)

ggdraw() +
  draw_plot(plot_species, 0, 0.85, 1, 0.15) +
  draw_plot(plot_latitude, 0, 0.35, 1, 0.5) +
  draw_plot(plot_r, 0, 0, 1, 0.35) +
  draw_plot_label("A", 0, 1) +
  draw_plot_label("B", 0, 0.85) +
  draw_plot_label("C", 0, 0.35)
ggsave("figures/figure1_supp.jpg", width = 6, height = 12)

# SIXTH FIGURE
individuals_data$sp_label = as.numeric(individuals_data$clean_genus_species)
first = 1
last = 80
full_sp_list = c()
for(i in 1:12){
  sp_list = unique(species_stats$genus_species)[first:last]
  if(!is.na(sp_list[80])){
    inds_df = individuals_data[individuals_data$clean_genus_species %in% sp_list,]
    inds_plot = ggplot(inds_df, aes(x = temperature, y = massing)) +
      geom_point(color = "gray48", size = 0.3) +
      facet_wrap(~sp_label, scales = "free", ncol = 8) +
      geom_smooth(method = "lm", se = FALSE, color = "black") +
      labs(x = expression("Mean annual temperature " (degree~C)), y = "Mass (g)") +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            strip.background = element_blank(),
            strip.text.x = element_text(size = 6, margin = margin(.5, 0, .5, 0)),
            axis.text = element_text(size = 5))
    ggsave(filename = paste("figures/", first, ".jpg", sep = ""), plot = inds_plot, width = 7, height = 9.25)
    sp_list = noquote(paste(sp_list, collapse = ", "))
    full_sp_list = append(full_sp_list, sp_list)
    first = first + 80
    last = last + 80
  }
}

sp_number = 1
for(i in 1:nrow(species_stats)){
  sp_number_par = paste("(", sp_number, ")", sep = "")
  number_w_sp = paste(sp_number_par, as.character(species_stats$genus_species[i]))
  number_w_sp_w_comma = cat(paste(number_w_sp, ", ", sep = ""))
  sp_number = sp_number + 1
}

# SEVENTH FIGURE
eol_df$migration[eol_df$Migratory.status == "Altitudinal Migrant" | eol_df$Migratory.status == "Full Migrant" | eol_df$Migratory.status == "Nomadic"] <- "migrant"
eol_df$migration[is.na(eol_df$migration)] <- "nonmigrant"

species_stats = left_join(species_stats, eol_df, by = c("genus_species" = "Scientific.name")) %>%
  select(-c(SIS.ID, Sequence, Family, X2016.IUCN.Red.List.Category, Possibly.Extinct., Possibly.Extinct.in.the.Wild., Migratory.status))

species_stats$temp_pvalue_adjust = p.adjust(species_stats$temp_pvalue, method = "fdr")
species_stats = species_stats %>%
  mutate(temp_stat_sig = ifelse(temp_pvalue_adjust < 0.05 & temp_slope < 0, "neg", 
                                ifelse(temp_pvalue_adjust < 0.05 & temp_slope > 0, "pos", "not")))

species_stats$temp_stat_sig = factor(species_stats$temp_stat_sig, levels = c("not", "neg", "pos"))
facets = c("migrant", "nonmigrant")
plot_migrants = ggplot(species_stats[species_stats$migration %in% facets,], aes(temp_r, fill = temp_stat_sig)) +
  geom_histogram(breaks = seq(-1, 1, by = 0.05), col = "black", size = 0.2) +
  scale_fill_manual(values = c("white", rgb(0, 0, 1, 0.5), rgb(0, 1, 0, 0.5)), 
                    labels = c("Not", "Negative", "Positive")) +
  labs(x = "r", y = "Number of species", fill = "Statistical significance: ") +
  geom_vline(xintercept = 0, size = 1) +
  theme(legend.position = "top",
        strip.background = element_rect(fill = "white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  facet_wrap(~ migration) +
  geom_text(data = data.frame(x = c(-0.7, -0.7, -0.2, -0.3, 0.6, 0.6), y = c(5, 6, 45, 30, 3, 4), label = c("15%", "16%", "79%", "79%", "6%", "5%"), migration = c("migrant", "nonmigrant", "migrant", "nonmigrant", "migrant", "nonmigrant")), aes(x, y, label = label), inherit.aes = FALSE)

ggdraw() +
  draw_plot(plot_migrants) +
  draw_plot_label(c("A", "B"), c(0.03, 0.53), c(0.955, 0.955))
ggsave("figures/figure7_supp.jpg", width = 10, height = 8)

