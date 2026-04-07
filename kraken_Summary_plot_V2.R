library(dplyr)
library(readr)
library(ggplot2)

# --------------------------
# SETTINGS
# --------------------------
input_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Contig_kraken_result/Illumina/kraken_contig_result/"
file_pattern <- "\\.report$"   # change if your kraken files use another extension
tax_rank <- "G"
output_plot <- "kraken_stacked_barplot_excluding_streptococcus_genus.png"

exclude_taxa <- c("Streptococcus")

rank_labels <- c(
  D = "Domain",
  P = "Phylum",
  C = "Class",
  O = "Order",
  F = "Family",
  G = "Genus",
  S = "Species"
)

tax_label <- ifelse(tax_rank %in% names(rank_labels), rank_labels[[tax_rank]], "Taxon")

# --------------------------
# FIND FILES
# --------------------------
files <- list.files(input_dir, pattern = "_illumina\\.report$", full.names = TRUE)

if (length(files) == 0) {
  stop("No files found. Check input_dir and file_pattern.")
}

# --------------------------
# READ ALL KRAKEN REPORT FILES
# --------------------------
all_data <- lapply(files, function(f) {
  df <- read_tsv(
    f,
    col_names = c("percent", "clade_reads", "taxon_reads", "rank", "taxid", "name"),
    show_col_types = FALSE
  )
  
  df %>%
    mutate(
      name = trimws(name),
      sample = sub("\\_illumina.report$", "", basename(f))
    ) %>%
    filter(rank == tax_rank) %>%
    select(sample, name, clade_reads)
}) %>% bind_rows()

# --------------------------
# DEBUG: CHECK STREPTOCOCCUS
# --------------------------
print(unique(all_data$name[grepl("Streptococcus", all_data$name, ignore.case = TRUE)]))

# --------------------------
# CALCULATE ORIGINAL TOTALS
# --------------------------
sample_totals <- all_data %>%
  group_by(sample) %>%
  summarise(total_reads = sum(clade_reads), .groups = "drop")

# --------------------------
# REMOVE EXCLUDED GENUS
# DO NOT RENORMALIZE
# --------------------------
plot_data <- all_data %>%
  filter(!tolower(name) %in% tolower(exclude_taxa)) %>%
  group_by(sample, name) %>%
  summarise(reads = sum(clade_reads), .groups = "drop") %>%
  left_join(sample_totals, by = "sample") %>%
  mutate(rel_abundance = reads / total_reads)

# --------------------------
# ORDER LEGEND FROM HIGHEST
# CONTAMINATION TO LOWEST
# --------------------------
taxa_order <- plot_data %>%
  group_by(name) %>%
  summarise(total_abundance = sum(rel_abundance), .groups = "drop") %>%
  arrange(desc(total_abundance)) %>%
  pull(name)

plot_data <- plot_data %>%
  mutate(name = factor(name, levels = taxa_order))

# --------------------------
# COLORBLIND-FRIENDLY RANDOM COLORS
# --------------------------
set.seed(123)   # remove this line if you want different colors every run

n_taxa <- length(taxa_order)

# Okabe-Ito base palette (colorblind-friendly)
okabe_ito <- c(
  "#000000",  # black
  "#0072B2", # blue
  "#E69F00", # orange
  "#F0E442", # yellow
  "#56B4E9", # sky blue
  "#D55E00", # vermillion
  "#CC79A7", # reddish purple
  "#009E73" # bluish green
)

# Expand palette if there are more taxa than base colors
color_fun <- colorRampPalette(okabe_ito)
cb_colors <- color_fun(n_taxa)

# Randomize assignment so similar abundances don't get similar colors
cb_colors <- sample(cb_colors)

names(cb_colors) <- taxa_order

# --------------------------
# PLOT
# --------------------------
p <- ggplot(plot_data, aes(x = sample, y = rel_abundance, fill = name)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = cb_colors) +
  labs(
    x = "Sample",
    y = "Relative Abundance %",
    fill = tax_label,
    title = "Kraken Results For Illumina Assemblies at Genus Level (Excluding Streptococcus)"
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p)

ggsave(output_plot, p, width = 12, height = 7, dpi = 300)