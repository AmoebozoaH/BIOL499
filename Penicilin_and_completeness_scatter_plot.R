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
    ),
    Match_num = case_when(
      Match == "No match" ~ 0,
      Match == "Match" ~ 1,
      TRUE ~ NA_real_
    )
  )

# ----------------------------
# 4. Merge with completeness
# ----------------------------
df <- pen_long %>%
  left_join(comp_long, by = c("Sample", "Method")) %>%
  filter(!is.na(Completeness), !is.na(Match))

# Optional: set method order
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

# ----------------------------
# 5. Scatter / jitter plot
# ----------------------------
ggplot(df, aes(x = Completeness, y = Match_num, color = Match)) +
  geom_jitter(height = 0.08, width = 0, size = 2, alpha = 0.8) +
  facet_wrap(~ Method) +
  scale_y_continuous(
    breaks = c(0, 1),
    labels = c("No match", "Match")
  ) +
  scale_color_manual(
    values = c("Match" = "#4DAF4A", "No match" = "#E41A1C")
  ) +
  labs(
    x = "Genome completeness",
    y = "Penicillin match",
    color = "Penicillin match",
    title = "Genome Completeness versus Penicillin Match For Different Assembly Methods",
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )