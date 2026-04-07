library(tidyverse)

folder <- "C:/Users/Amoeb/Documents/zsw2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/checkM_sum"

files <- list.files(path = folder, pattern = "_quality_report\\.tsv$", full.names = TRUE)

read_checkm <- function(f) {
  df <- read.delim(f, header = TRUE, sep = "\t", check.names = FALSE)
  
  method <- basename(f) %>%
    str_remove("_quality_report\\.tsv$")
  
  df %>%
    dplyr::select(Completeness, Contamination) %>%
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

p <- ggplot(all_checkm, aes(x = Contamination, y = Completeness, color = Method)) +
  geom_point(size = 2.8, alpha = 0.9) +
  geom_hline(yintercept = 90, linetype = "dashed") +
  geom_vline(xintercept = 5, linetype = "dashed") +
  scale_color_manual(values = c(
    "illumina" = "#92140C",
    "nanopore" = "#FF8019",
    "nanopore_homopolisher" = "#FAE603",
    "nanopore_medaka" = "#28E10A",
    "nanopore_medaka_homopolisher" = "#3BB5FF",
    "nanopore_racon_iteration3" = "#0500C7",
    "nanopore_racon_medaka" = "#00798C",
    "nanopore_medaka_polypolish_pypolca" = "#393E41"
  )) +
  labs(
    title = "Genome Completeness vs Contamination Across Different Methods",
    x = "Contamination (%)",
    y = "Completeness (%)",
    color = "Method"
  ) +
  theme_bw(base_size = 12)


print(p)

ggsave("completeness_vs_contamination.png", p, width = 8, height = 6, dpi = 300)