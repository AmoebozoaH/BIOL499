library(tidyverse)

# Folder containing your CheckM reports
folder <- "C:/Users/Amoeb/Documents/zsw2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/checkM_sum"

# Get all CheckM report files
files <- list.files(
  path = folder,
  pattern = "_quality_report\\.tsv$",
  full.names = TRUE
)

# Function to read one CheckM report and keep Contig_N50
read_checkm_n50 <- function(f) {
  df <- read.delim(
    f,
    header = TRUE,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    quote = ""
  )
  
  method <- basename(f) %>%
    str_remove("_quality_report\\.tsv$")
  
  df %>%
    dplyr::select(Name, Contig_N50) %>%
    mutate(Method = method)
}

# Combine all files
all_n50 <- purrr::map_dfr(files, read_checkm_n50)

# Set method order
method_order <- c(
  "illumina",
  "nanopore",
  "nanopore_homopolisher",
  "nanopore_medaka",
  "nanopore_medaka_homopolisher",
  "nanopore_racon_iteration3",
  "nanopore_racon_medaka",
  "nanopore_medaka_polypolish_pypolca"
)

all_n50 <- all_n50 %>%
  mutate(Method = factor(Method, levels = method_order))

# Plot N50
p <- ggplot(all_n50, aes(x = Method, y = Contig_N50)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.85) +
  geom_jitter(width = 0.15, alpha = 0.6, size = 2) +
  labs(
    title = "Contig N50 Across Different Assembly Methods",
    x = "Method",
    y = "Contig N50"
  ) +
  theme_bw(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )

print(p)