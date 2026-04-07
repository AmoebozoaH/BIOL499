# install.packages(c("readxl", "tidyverse", "ggnewscale"))
library(readxl)
library(tidyverse)
library(ggnewscale)

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
# 3. Recode penicillin
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
# 4. Merge
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
# 6. Build plotting data
# ----------------------------
match_df <- df %>%
  transmute(
    Sample,
    Method,
    Variable = "Match",
    FillValue = Match,
    Label = Assembly_Result
  )

comp_df <- df %>%
  transmute(
    Sample,
    Method,
    Variable = "Completeness",
    FillValue = Completeness,
    Label = sprintf("%.2f", Completeness)
  )

# ----------------------------
# 7. Plot with two fill scales
# ----------------------------
ggplot() +
  # Match tiles
  geom_tile(
    data = match_df,
    aes(x = Variable, y = Sample, fill = FillValue),
    color = "grey85", linewidth = 0.3
  ) +
  geom_text(
    data = match_df,
    aes(x = Variable, y = Sample, label = Label),
    size = 2.4
  ) +
  scale_fill_manual(
    name = "Penicillin match",
    values = c(
      "Match" = "#7CA982",
      "No match" = "#EDAE49"
    ),
    na.value = "grey85"
  ) +
  
  ggnewscale::new_scale_fill() +
  
  # Completeness tiles
  geom_tile(
    data = comp_df,
    aes(x = Variable, y = Sample, fill = FillValue),
    color = "grey85", linewidth = 0.3
  ) +
  geom_text(
    data = comp_df,
    aes(x = Variable, y = Sample, label = Label),
    size = 2.4
  ) +
  scale_fill_gradient(
    name = "Genome completeness",
    low = "#E2EFF6",
    high = "#4893C6",
    na.value = "grey85"
  ) +
  
  facet_wrap(~ Method, nrow = 1) +
  labs(
    x = NULL,
    y = NULL,
    title = "Penicillin agreement and genome completeness by assembly method",
    subtitle = "I and R are both treated as R"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    strip.text = element_text(face = "bold", size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    panel.spacing.x = unit(0.8, "lines"),
    legend.position = "right"
  )