library(readxl)
library(tidyverse)
library(grid)

pen_file  <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_sum.xlsx"
comp_file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Merged_completeness.xlsx"
gsize_file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Genome_size_sum.xlsx"

pen <- read_excel(pen_file) %>%
  rename(Sample = Index)

comp <- read_excel(comp_file) %>%
  rename(Sample = Name)

gsize <- read_excel(gsize_file) %>%
  rename(Sample = Name)

pen_long <- pen %>%
  pivot_longer(
    cols = -c(Sample, Clinical),
    names_to = "Method",
    values_to = "Resistance"
  )

comp_long <- comp %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Completeness"
  )

gsize_long <- gsize %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Genome_Size"
  )

df <- pen_long %>%
  left_join(comp_long, by = c("Sample", "Method")) %>%
  left_join(gsize_long, by = c("Sample", "Method"))

sample_order <- df %>%
  distinct(Sample, Clinical) %>%
  arrange(Clinical, Sample) %>%
  pull(Sample)

df$Sample <- factor(df$Sample, levels = rev(sample_order))

method_order <- c(
  "Illumina",
  "Nanopore",
  "Nanopore_racon",
  "Nanopore_medaka",
  "Nanopore_homopolisher",
  "Nanopore_racon_medaka",
  "Nanopore_medaka_homopolisher",
  "Hybrid"
)

df$Method <- factor(df$Method, levels = method_order)

plot_df <- bind_rows(
  df %>%
    transmute(
      Sample,
      Method,
      Variable = "Resistance",
      Value = as.character(Resistance),
      Label = as.character(Resistance)
    ),
  df %>%
    transmute(
      Sample,
      Method,
      Variable = "Completeness",
      Value = as.character(Completeness),
      Label = sprintf("%.2f", Completeness)
    ),
  df %>%
    transmute(
      Sample,
      Method,
      Variable = "Genome size",
      Value = as.character(Genome_Size),
      Label = sprintf("%.2f", Genome_Size / 1e6)
    )
)

plot_df$Variable <- factor(
  plot_df$Variable,
  levels = c("Resistance", "Completeness", "Genome size")
)

res_cols <- c(
  "S" = "#4DAF4A",
  "I" = "#FFD92F",
  "R" = "#E41A1C"
)

comp_pal <- colorRampPalette(c("#F7FBFF", "#6BAED6", "#08306B"))
gsize_pal <- colorRampPalette(c("#FFF5EB", "#FDAE6B", "#A63603"))

comp_vals <- df$Completeness
comp_breaks <- seq(
  min(comp_vals, na.rm = TRUE),
  max(comp_vals, na.rm = TRUE),
  length.out = 101
)

gsize_vals <- df$Genome_Size
gsize_breaks <- seq(
  min(gsize_vals, na.rm = TRUE),
  max(gsize_vals, na.rm = TRUE),
  length.out = 101
)

plot_df <- plot_df %>%
  mutate(
    Fill = case_when(
      Variable == "Resistance" ~ res_cols[Value],
      Variable == "Completeness" ~ {
        bins <- cut(
          as.numeric(Value),
          breaks = comp_breaks,
          labels = FALSE,
          include.lowest = TRUE
        )
        comp_pal(100)[bins]
      },
      Variable == "Genome size" ~ {
        bins <- cut(
          as.numeric(Value),
          breaks = gsize_breaks,
          labels = FALSE,
          include.lowest = TRUE
        )
        gsize_pal(100)[bins]
      }
    )
  )

ggplot(plot_df, aes(x = Variable, y = Sample, fill = Fill)) +
  geom_tile(color = "grey85", linewidth = 0.3) +
  geom_text(aes(label = Label), size = 2.4) +
  scale_fill_identity() +
  facet_wrap(~ Method, nrow = 1) +
  labs(
    x = NULL,
    y = NULL,
    title = "Penicillin resistance, genome completeness, and genome size by assembly method"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    strip.text = element_text(face = "bold", size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    panel.spacing.x = unit(0.8, "lines")
  )