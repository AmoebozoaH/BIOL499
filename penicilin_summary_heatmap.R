library(readxl)
library(pheatmap)

file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_sum.xlsx"

# Read Excel file
df <- read_excel(file)

# Make duplicate column names unique
colnames(df) <- make.unique(colnames(df))

# First column = sample names
sample_ids <- df[[1]]

# Remove first column from plotting matrix
df_plot <- df[, -1]

# Standardize values
df_plot[] <- lapply(df_plot, function(x) toupper(trimws(as.character(x))))

# Keep only valid S / I / R values, everything else becomes NA
valid_vals <- c("S", "I", "R")
df_plot[] <- lapply(df_plot, function(x) ifelse(x %in% valid_vals, x, NA))

# Map S / I / R to numeric values
sir_map <- c("S" = 0, "I" = 1, "R" = 2)
mat_num <- as.data.frame(lapply(df_plot, function(x) sir_map[x]))
mat_num <- as.matrix(mat_num)

# Add row names
rownames(mat_num) <- sample_ids

# Matrix of labels to display inside cells
mat_labels <- as.matrix(df_plot)
rownames(mat_labels) <- sample_ids

# Draw heatmap
pheatmap(
  mat_num,
  display_numbers = mat_labels,
  number_color = "black",
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  color = c("#EE9B00", "#BB3E03", "#6A040F"),
  breaks = c(-0.5, 0.5, 1.5, 2.5),
  legend_breaks = c(0, 1, 2),
  legend_labels = c("S", "I", "R"),
  border_color = "grey80",
  fontsize_row = 8,
  fontsize_col = 10,
  angle_col = 45,
  main = "Penicillin Susceptibility Heatmap"
)