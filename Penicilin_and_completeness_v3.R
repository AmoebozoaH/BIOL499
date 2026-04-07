library(readxl)
library(tidyverse)

# ----------------------------
# 1. Read data
# ----------------------------

pen_file  <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_sum.xlsx"
comp_file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Merged_completeness.xlsx"

pen <- read_excel(pen_file) %>%
  rename(Sample = Index)

comp <- read_excel(comp_file) %>%
  rename(Sample = Name)

# ----------------------------
# 2. Long format
# ----------------------------
pen_long <- pen %>%
  pivot_longer(
    cols = -c(Sample, Clinical),
    names_to = "Method",
    values_to = "Assembly_Result"
  )

comp_long <- comp %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Completeness"
  )

# ----------------------------
# 3. Recode penicillin:
#    I and R both count as R
# ----------------------------
to_binary_SR <- function(x) {
  case_when(
    x == "S" ~ "S",
    x %in% c("I", "R") ~ "R",
    TRUE ~ NA_character_
  )
}

pen_long <- pen_long %>%
  mutate(
    Clinical_bin = to_binary_SR(Clinical),
    Assembly_bin = to_binary_SR(Assembly_Result),
    Match = case_when(
      is.na(Clinical_bin) | is.na(Assembly_bin) ~ NA_character_,
      Clinical_bin == Assembly_bin ~ "Match",
      TRUE ~ "No match"
    )
  )

# ----------------------------
# 4. Merge with completeness
# ----------------------------
df <- pen_long %>%
  left_join(comp_long, by = c("Sample", "Method"))

# ----------------------------
# 5. Order samples and methods
# ----------------------------
sample_order <- df %>%
  distinct(Sample, Clinical_bin) %>%
  arrange(Clinical_bin, Sample) %>%
  pull(Sample)

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

df <- df %>%
  mutate(
    Sample = factor(Sample, levels = rev(sample_order)),
    Method = factor(Method, levels = method_order)
  )

# ----------------------------
# 6. Build plotting table:
#    one Match column + one Completeness column per method
# ----------------------------
plot_df <- bind_rows(
  df %>%
    transmute(
      Sample,
      Method,
      Variable = "Match",
      Value = as.character(Match),
      Label = as.character(Assembly_Result)
    ),
  df %>%
    transmute(
      Sample,
      Method,
      Variable = "Completeness",
      Value = as.character(round(Completeness, 2)),
      Label = sprintf("%.2f", Completeness)
    )
)

# ----------------------------
# 7. Colors
# ----------------------------
match_cols <- c(
  "Match" = "#7CA982",
  "No match" = "#EDAE49"
)

comp_pal <- colorRampPalette(c("#8C1C13", "#E1ECF7", "#71A5DE"))

comp_vals <- df$Completeness
comp_breaks <- seq(
  min(comp_vals, na.rm = TRUE),
  max(comp_vals, na.rm = TRUE),
  length.out = 101
)

plot_df <- plot_df %>%
  mutate(
    Fill = case_when(
      Variable == "Match" ~ match_cols[Value],
      Variable == "Completeness" ~ {
        bins <- cut(
          as.numeric(Value),
          breaks = comp_breaks,
          labels = FALSE,
          include.lowest = TRUE
        )
        comp_pal(100)[bins]
      }
    )
  )

# ----------------------------
# 8. Plot
# ----------------------------
ggplot(plot_df, aes(x = Variable, y = Sample, fill = Fill)) +
  geom_tile(color = "grey80", linewidth = 0.3) +
  geom_text(aes(label = Label), size = 2.4) +
  scale_fill_identity() +
  facet_wrap(~ Method, nrow = 1) +
  labs(
    x = NULL,
    y = NULL,
    title = "Penicillin agreement and genome completeness by assembly method",
    subtitle = "Penicillin agreement uses clinical result; I and R are both treated as R"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    strip.text = element_text(face = "bold", size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    panel.spacing.x = unit(0.8, "lines")
  )