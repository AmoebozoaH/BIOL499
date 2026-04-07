# =========================
# Plot Kraken nanopore species results
# =========================

library(data.table)
library(dplyr)
library(ggplot2)
library(stringr)
library(scales)
library(RColorBrewer)   # add this

# -------------------------
# 1. Set folder path
# -------------------------
report_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Contig_kraken_result/Illumina/kraken_contig_result/"

# -------------------------
# 2. Color options
# -------------------------
# Option A: use a Brewer palette name
use_brewer_palette <- TRUE
brewer_palette_name <- "Set3"   # try: "Set3", "Paired", "Dark2", "Spectral"

# Option B: use your own custom colors
use_custom_colors <- TRUE
custom_colors <- c(
  "#1b9e77", "#8dd3c7","#ffd92f", "#e5c494","#80b1d3"
)

# -------------------------
# 3. Find all nanopore Kraken report files
# -------------------------
report_files <- list.files(
  path = report_dir,
  pattern = "_illumina_bracken_species\\.report$",
  full.names = TRUE
)

if (length(report_files) == 0) {
  stop("No Kraken nanopore report files found.")
}

# -------------------------
# 4. Function to read one Kraken report
# -------------------------
read_kraken_report <- function(file) {
  
  dt <- fread(file, header = FALSE, sep = "\t", fill = TRUE)
  
  if (ncol(dt) == 1) {
    dt <- fread(file, header = FALSE, fill = TRUE)
  }
  
  dt <- dt[, 1:6, with = FALSE]
  colnames(dt) <- c("percent", "clade_reads", "taxon_reads", "rank_code", "taxid", "name")
  
  dt$name <- trimws(dt$name)
  
  filename <- basename(file)
  sample_name <- str_extract(filename, ".*_barcode\\d+(?:_\\d+)?")
  
  dt$sample <- sample_name
  
  return(dt)
}

# -------------------------
# 5. Read and combine all reports
# -------------------------
all_reports <- lapply(report_files, read_kraken_report) %>%
  bind_rows()

# -------------------------
# 6. Keep species-level only
# -------------------------
species_df <- all_reports %>%
  filter(rank_code == "S")

if (nrow(species_df) == 0) {
  stop("No species-level entries found (rank_code == 'S').")
}

# -------------------------
# 7. Calculate relative abundance per sample
# -------------------------
species_df <- species_df %>%
  group_by(sample) %>%
  mutate(relative_abundance = taxon_reads / sum(taxon_reads)) %>%
  ungroup()

# -------------------------
# 8. Keep top N species overall
# -------------------------
top_n <- 20

top_species <- species_df %>%
  group_by(name) %>%
  summarise(total_abundance = sum(relative_abundance), .groups = "drop") %>%
  arrange(desc(total_abundance)) %>%
  slice_head(n = top_n) %>%
  pull(name)

plot_df <- species_df %>%
  mutate(name = ifelse(name %in% top_species, name, "Other")) %>%
  group_by(sample, name) %>%
  summarise(relative_abundance = sum(relative_abundance), .groups = "drop")

plot_df$sample <- factor(plot_df$sample, levels = unique(species_df$sample))

# -------------------------
# 9. Plot
# -------------------------
p <- ggplot(plot_df, aes(x = sample, y = relative_abundance, fill = name)) +
  geom_bar(stat = "identity", width = 0.8) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Illumina Braken species-level classification",
    x = "Sample",
    y = "Relative Abundance",
    fill = "Species"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.title.x = element_text(size = 17, face = "bold"),
    legend.text = element_text(size = 10),
    legend.title = element_text(size = 10),
    plot.title = element_text(face = "bold")
  )

# -------------------------
# 10. Apply colors
# -------------------------
n_groups <- length(unique(plot_df$name))

if (use_custom_colors) {
  p <- p + scale_fill_manual(values = custom_colors[seq_len(n_groups)])
} else if (use_brewer_palette) {
  # brewer.pal max is palette-dependent, so interpolate if needed
  base_cols <- brewer.pal(min(max(3, n_groups), 12), brewer_palette_name)
  if (n_groups > length(base_cols)) {
    palette_cols <- colorRampPalette(base_cols)(n_groups)
  } else {
    palette_cols <- base_cols[seq_len(n_groups)]
  }
  p <- p + scale_fill_manual(values = palette_cols)
}

print(p)

ggsave(
  "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/Writeup/Plot_collection/Figure3_bracken_contamination.png",
  plot = p,
  width = 14.63,
  height = 7.63,
  units = "in",
  dpi = 300
)