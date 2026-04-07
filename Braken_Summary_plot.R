library(dplyr)
library(readr)
library(ggplot2)

# --------------------------
# SETTINGS
# --------------------------
# set directory to location that contain all the braken output
# The file needed here are the .braken files
input_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Reads_kraken_result/illumina_kraken_result/"
# the directory might contain other kraken result, extract braken target using regex
file_pattern <- "\\.bracken$"
tax_rank <- "S"
output_plot <- "bracken_stacked_barplot_excluding_spneumoniae.png"

# exclude the target species
exclude_species <- c("Streptococcus pneumoniae")

# --------------------------
# FIND FILES
# --------------------------
files <- list.files(input_dir, pattern = file_pattern, full.names = TRUE)

if (length(files) == 0) {
  stop("No files found. Check input_dir and file_pattern.")
}

# --------------------------
# READ ALL BRACKEN FILES
# --------------------------
all_data <- lapply(files, function(f) {
  df <- read_tsv(f, show_col_types = FALSE)
  
  if (!all(c("name", "taxonomy_lvl", "new_est_reads") %in% colnames(df))) {
    stop(paste("Missing expected columns in:", basename(f)))
  }
  
  df %>%
    filter(taxonomy_lvl == tax_rank) %>%
    select(name, new_est_reads) %>%
    mutate(sample = sub("\\.bracken$", "", basename(f)))
}) %>% bind_rows()

# --------------------------
# CALCULATE ORIGINAL TOTALS
# --------------------------
sample_totals <- all_data %>%
  group_by(sample) %>%
  summarise(total_reads = sum(new_est_reads), .groups = "drop")

# --------------------------
# REMOVE EXCLUDED SPECIES
# DO NOT RENORMALIZE
# --------------------------
# for if there are 100# excluded species in a file, it is not included on the plot
plot_data <- all_data %>%
  filter(!(name %in% exclude_species)) %>%
  group_by(sample, name) %>%
  summarise(reads = sum(new_est_reads), .groups = "drop") %>%
  left_join(sample_totals, by = "sample") %>%
  mutate(rel_abundance = reads / total_reads)

# --------------------------
# PLOT ALL REMAINING SPECIES
# --------------------------
p <- ggplot(plot_data, aes(x = sample, y = rel_abundance, fill = name)) +
  geom_bar(stat = "identity") +
  labs(
    x = "Sample",
    y = "Relative abundance (original total)",
    fill = "Species",
    title = "Braken Result for Nanopore Reads on Species Abundancy Excluding Streptococcus pneumoniae"
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p)

ggsave(output_plot, p, width = 12, height = 7, dpi = 300)