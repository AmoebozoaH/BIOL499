library(tidyverse)

folder <- "C:/Users/Amoeb/Documents/zsw2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/checkM_sum"

files <- list.files(path = folder, pattern = "_quality_report\\.tsv$", full.names = TRUE)

read_checkm <- function(f) {
  df <- read.delim(f, header = TRUE, sep = "\t", check.names = FALSE)
  
  method <- basename(f) %>%
    str_remove("_quality_report\\.tsv$")
  
  df %>%
    dplyr::select(Completeness) %>%
    mutate(Method = method)
}

all_checkm <- purrr::map_dfr(files, read_checkm)

all_checkm <- all_checkm %>%
  mutate(
    Method = factor(
      Method,
      levels = c(
        "illumina",
        "nanopore",
        "nanopore_racon_iteration3",
        "nanopore_medaka",
        "nanopore_homopolisher",
        "nanopore_racon_medaka",
        "nanopore_medaka_homopolisher",
        "nanopore_medaka_polypolish_pypolca"
      )
    )
  )

p <- ggplot(all_checkm, aes(x = Method, y = Completeness)) +
  geom_boxplot(outlier.shape = NA, width = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.6, size = 2) +
  labs(
    title = "Genome Completeness Across Assembly Methods",
    x = "Method",
    y = "Completeness (%)"
  ) +
  theme_bw(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p)

#ggsave("genome_completeness_boxplot.png", p, width = 10, height = 6, dpi = 300)