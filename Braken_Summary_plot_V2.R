library(dplyr)
library(readr)
library(ggplot2)
library(stringr)

# --------------------------
# SETTINGS
# --------------------------
# Parent directory containing all nanopore combo folders
parent_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Contig_kraken_result"

# Output figure
output_plot <- "kraken_stacked_barplot_nanopore_faceted_by_sample.png"

# Keep only this taxonomic rank from Kraken
# "S" = species
tax_rank <- "S"

# Target species to exclude from the plot
exclude_species <- c("Streptococcus pneumoniae")

# Regex for sample IDs like:
# i12_02_barcode35
# i7_4_barcode8
sample_pattern <- "^i\\d{1,2}_\\d{1,2}_barcode\\d+"

# Kraken file pattern
# change this if your files end with something else
file_pattern <- "\\.(txt|tsv|report|kreport|kraken)$"

# --------------------------
# FIND NANOPORE COMBO FOLDERS
# --------------------------
combo_dirs <- list.dirs(parent_dir, full.names = TRUE, recursive = FALSE)
combo_dirs <- combo_dirs[grepl("^nanopore", basename(combo_dirs), ignore.case = TRUE)]

cat("Combo folders found:\n")
print(basename(combo_dirs))

if (length(combo_dirs) == 0) {
  stop("No combo folders starting with 'nanopore' were found.")
}

# --------------------------
# FIND KRAKEN RESULT FILES
# --------------------------
kraken_info <- lapply(combo_dirs, function(combo_dir) {
  kraken_dir <- file.path(combo_dir, "kraken_contig_result")
  
  cat("\nChecking folder:", kraken_dir, "\n")
  
  if (!dir.exists(kraken_dir)) {
    message("Skipping missing folder: ", kraken_dir)
    return(NULL)
  }
  
  files <- list.files(
    kraken_dir,
    pattern = file_pattern,
    full.names = TRUE
  )
  
  cat("  Kraken files found:", length(files), "\n")
  
  if (length(files) == 0) {
    return(NULL)
  }
  
  data.frame(
    file = files,
    combo = basename(combo_dir),
    stringsAsFactors = FALSE
  )
}) %>% bind_rows()

if (nrow(kraken_info) == 0) {
  stop("No Kraken result files were found in any nanopore combo folder.")
}

cat("\nTotal Kraken files found:", nrow(kraken_info), "\n")
print(head(kraken_info))

# --------------------------
# READ ALL KRAKEN FILES
# --------------------------
# Assumes standard Kraken report columns:
# percent, clade_reads, taxon_reads, rank_code, taxid, name
all_data_list <- lapply(seq_len(nrow(kraken_info)), function(i) {
  f <- kraken_info$file[i]
  combo_name <- kraken_info$combo[i]
  
  cat("\nReading:", basename(f), "| combo:", combo_name, "\n")
  
  # Try reading as tab-delimited without header
  df <- read_tsv(
    f,
    col_names = FALSE,
    show_col_types = FALSE,
    progress = FALSE
  )
  
  cat("  Rows in file:", nrow(df), "\n")
  cat("  Columns in file:", ncol(df), "\n")
  
  # Standard Kraken report should have at least 6 columns
  if (ncol(df) < 6) {
    warning("Skipping file with fewer than 6 columns: ", basename(f))
    return(NULL)
  }
  
  # Rename first 6 columns to standard Kraken report fields
  colnames(df)[1:6] <- c(
    "percent",
    "clade_reads",
    "taxon_reads",
    "rank_code",
    "taxid",
    "name"
  )
  
  file_base <- tools::file_path_sans_ext(basename(f))
  sample_id <- str_extract(file_base, sample_pattern)
  
  cat("  Extracted sample_id:", sample_id, "\n")
  
  if (is.na(sample_id)) {
    warning("Could not extract sample ID from file: ", basename(f))
    return(NULL)
  }
  
  # Clean indentation in taxon names from Kraken reports
  df2 <- df %>%
    mutate(
      name = str_trim(name),
      rank_code = str_trim(rank_code)
    ) %>%
    filter(rank_code == tax_rank) %>%
    select(name, taxon_reads) %>%
    mutate(
      sample = sample_id,
      combo = combo_name,
      file_name = file_base
    )
  
  cat("  Rows after species filter:", nrow(df2), "\n")
  
  df2
})

all_data <- bind_rows(all_data_list)

cat("\nRows in all_data:", nrow(all_data), "\n")

if (nrow(all_data) == 0) {
  stop("No usable Kraken rows found. Check file format and rank_code values.")
}

cat("\nUnique samples:\n")
print(unique(all_data$sample))

cat("\nUnique combos:\n")
print(unique(all_data$combo))

# --------------------------
# CALCULATE TOTALS
# --------------------------
sample_totals <- all_data %>%
  group_by(sample, combo) %>%
  summarise(total_reads = sum(taxon_reads), .groups = "drop")

# --------------------------
# FILTER EXCLUDED SPECIES
# DO NOT RENORMALIZE
# --------------------------
plot_data <- all_data %>%
  filter(!(name %in% exclude_species)) %>%
  group_by(sample, combo, name) %>%
  summarise(reads = sum(taxon_reads), .groups = "drop") %>%
  left_join(sample_totals, by = c("sample", "combo")) %>%
  mutate(rel_abundance = reads / total_reads)

cat("\nRows in plot_data:", nrow(plot_data), "\n")

if (nrow(plot_data) == 0) {
  stop("plot_data is empty after filtering.")
}

# --------------------------
# OPTIONAL: COLLAPSE LOW-ABUNDANCE TAXA INTO 'Other'
# keep top 15 species overall
# --------------------------
top_species <- plot_data %>%
  group_by(name) %>%
  summarise(total = sum(reads), .groups = "drop") %>%
  arrange(desc(total)) %>%
  slice_head(n = 15) %>%
  pull(name)

plot_data <- plot_data %>%
  mutate(name = ifelse(name %in% top_species, name, "Other")) %>%
  group_by(sample, combo, name, total_reads) %>%
  summarise(reads = sum(reads), .groups = "drop") %>%
  mutate(rel_abundance = reads / total_reads)

# --------------------------
# ORDER COMBOS
# --------------------------
combo_order <- c(
  "Nanopore",
  "Nanopore_homopolisher",
  "Nanopore_medaka",
  "Nanopore_medaka_homopolisher",
  "Nanopore_racon",
  "Nanopore_racon_medaka"
)

combo_order <- combo_order[combo_order %in% unique(plot_data$combo)]

if (length(combo_order) > 0) {
  plot_data <- plot_data %>%
    mutate(combo = factor(combo, levels = combo_order))
} else {
  plot_data <- plot_data %>%
    mutate(combo = factor(combo, levels = unique(combo)))
}

plot_data <- plot_data %>%
  mutate(sample = factor(sample, levels = unique(sample)))

# --------------------------
# PLOT
# --------------------------
p <- ggplot(plot_data, aes(x = combo, y = rel_abundance, fill = name)) +
  geom_col() +
  facet_wrap(~ sample, ncol = 2) +
  labs(
    x = "Polisher combination",
    y = "Relative abundance",
    fill = "Species",
    title = "Kraken contamination results for nanopore assemblies",
    subtitle = "Each panel is one sample; bars compare polishing combinations"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold")
  )

print(p)
