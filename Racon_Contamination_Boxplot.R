# ============================================
# CheckM contamination plot across Racon iterations
# RStudio version
# ============================================

# ---- 1. Set your input directory here ----
input_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/nanopore_racon/CheckM_Result_20260308/"

# Example:
# input_dir <- "/Users/yourname/Desktop/checkm_reports"
# input_dir <- "C:/Users/yourname/Desktop/checkm_reports"

if (!dir.exists(input_dir)) {
  stop(sprintf("Directory does not exist: %s", input_dir))
}

# ---- 2. Load packages ----
suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
  library(dplyr)
  library(stringr)
})

# ---- 3. Find TSV files ----
files <- list.files(input_dir, pattern = "\\.tsv$", full.names = TRUE)

if (length(files) == 0) {
  stop("No .tsv files found in the input directory.")
}

message("Found files:")
print(basename(files))

# ---- 4. Function to extract iteration number from filename ----
extract_iteration <- function(filename) {
  base <- basename(filename)
  m <- str_match(base, "iteration\\s*_?\\s*([0-9]+)")
  
  if (!is.na(m[1, 2])) {
    return(as.integer(m[1, 2]))
  } else {
    return(NA_integer_)
  }
}

# ---- 5. Read all files and combine ----
all_data <- lapply(files, function(f) {
  df <- read_tsv(f, show_col_types = FALSE)
  
  message(sprintf("\nColumns in %s:", basename(f)))
  print(colnames(df))
  
  # Try to automatically detect contamination column
  contamination_candidates <- colnames(df)[tolower(colnames(df)) %in%
                                             c("contamination", "checkm_contamination")]
  
  if (length(contamination_candidates) == 0) {
    contamination_candidates <- colnames(df)[grepl("contamination", colnames(df), ignore.case = TRUE)]
  }
  
  if (length(contamination_candidates) == 0) {
    stop(sprintf("Could not find a contamination column in file: %s", basename(f)))
  }
  
  contamination_col <- contamination_candidates[1]
  
  df %>%
    mutate(
      file = basename(f),
      iteration_num = extract_iteration(f),
      contamination = .data[[contamination_col]]
    ) %>%
    select(file, iteration_num, contamination)
})

plot_df <- bind_rows(all_data) %>%
  filter(!is.na(contamination), !is.na(iteration_num)) %>%
  mutate(iteration = factor(iteration_num, levels = sort(unique(iteration_num))))

if (nrow(plot_df) == 0) {
  stop("No usable contamination values found after filtering.")
}

# ---- 6. Make plot ----
p <- ggplot(plot_df, aes(x = iteration, y = contamination)) +
  geom_boxplot(
    outlier.shape = NA,
    width = 0.55,
    fill = "mistyrose",
    alpha = 0.5
  ) +
  geom_jitter(
    width = 0.18,
    height = 0,
    alpha = 0.7,
    size = 2
  ) +
  labs(
    title = "CheckM Contamination Across Racon Iterations",
    x = "Racon Iteration",
    y = "Contamination (%)"
  ) +
  theme_bw(base_size = 13)

print(p)

# ---- 7. Save plot ----
output_file <- file.path(input_dir, "checkm_contamination_jitter_boxplot.png")
ggsave(output_file, p, width = 7, height = 5, dpi = 300)

message(sprintf("\nPlot saved to: %s", output_file))