# Install once if needed:
# install.packages(c("readxl", "tidyverse", "ggnewscale"))

library(readxl)
library(tidyverse)
library(ggnewscale)

# ==========================================
# File paths
# ==========================================
pen_file  <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_sum.xlsx"
comp_file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Merged_completeness.xlsx"

# ==========================================
# Read files
# ==========================================
pen <- read_excel(pen_file)
comp <- read_excel(comp_file)

# ==========================================
# Rename columns
# Adjust penicillin method names if needed
# ==========================================
names(pen)[1] <- "Sample"
names(pen) <- make.unique(names(pen))

names(pen) <- c(
  "Sample",
  "Clinical",
  "Illumina",
  "Nanopore",
  "Nanopore_racon",
  "Nanopore_medaka",
  "Nanopore_homopolisher",
  "Nanopore_racon_medaka",
  "Nanopore_medaka_homopolisher",
  "Hybrid"
)

# remove clinical
pen <- pen %>% select(-Clinical)

names(comp)[1] <- "Sample"
names(comp) <- c(
  "Sample",
  "Illumina",
  "Nanopore",
  "Nanopore_racon",
  "Nanopore_medaka",
  "Nanopore_homopolisher",
  "Nanopore_racon_medaka",
  "Nanopore_medaka_homopolisher",
  "Hybrid"
)

# ==========================================
# Keep shared samples only
# ==========================================
common_samples <- intersect(pen$Sample, comp$Sample)

pen  <- pen  %>% filter(Sample %in% common_samples)
comp <- comp %>% filter(Sample %in% common_samples)

sample_order <- pen$Sample

method_levels <- c(
  "Illumina",
  "Nanopore",
  "Nanopore_racon",
  "Nanopore_medaka",
  "Nanopore_homopolisher",
  "Nanopore_racon_medaka",
  "Nanopore_medaka_homopolisher",
  "Hybrid"
)

# ==========================================
# Long data for penicillin
# ==========================================
pen_long <- pen %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Penicillin"
  ) %>%
  mutate(
    Sample = factor(Sample, levels = rev(sample_order)),
    Method = factor(Method, levels = method_levels),
    X = paste(Method, "Pen", sep = "_")
  )

# ==========================================
# Long data for completeness
# ==========================================
comp_long <- comp %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Completeness"
  ) %>%
  mutate(
    Sample = factor(Sample, levels = rev(sample_order)),
    Method = factor(Method, levels = method_levels),
    Completeness = as.numeric(Completeness),
    X = paste(Method, "Comp", sep = "_")
  )

# x-axis order: Pen then Comp for each method
x_order <- c(
  "Illumina_Pen", "Illumina_Comp",
  "Nanopore_Pen", "Nanopore_Comp",
  "Nanopore_racon_Pen", "Nanopore_racon_Comp",
  "Nanopore_medaka_Pen", "Nanopore_medaka_Comp",
  "Nanopore_homopolisher_Pen", "Nanopore_homopolisher_Comp",
  "Nanopore_racon_medaka_Pen", "Nanopore_racon_medaka_Comp",
  "Nanopore_medaka_homopolisher_Pen", "Nanopore_medaka_homopolisher_Comp",
  "Hybrid_Pen", "Hybrid_Comp"
)

pen_long$X  <- factor(pen_long$X, levels = x_order)
comp_long$X <- factor(comp_long$X, levels = x_order)

# ==========================================
# Plot
# ==========================================
p <- ggplot() +
  geom_tile(
    data = comp_long,
    aes(x = X, y = Sample, fill = Completeness),
    color = "white",
    linewidth = 0.3
  ) +
  scale_fill_gradient(
    low = "white",
    high = "steelblue",
    name = "Completeness (%)",
    na.value = "grey90"
  ) +
  new_scale_fill() +
  geom_tile(
    data = pen_long,
    aes(x = X, y = Sample, fill = Penicillin),
    color = "white",
    linewidth = 0.3
  ) +
  geom_text(
    data = pen_long,
    aes(x = X, y = Sample, label = Penicillin),
    size = 3
  ) +
  scale_fill_manual(
    values = c("S" = "#1b9e77", "I" = "#e6ab02", "R" = "#d95f02"),
    name = "Penicillin",
    na.value = "grey90"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

print(p)

ggsave(
  "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/paired_single_heatmap_no_clinical.png",
  p,
  width = 14,
  height = 14,
  dpi = 300
)