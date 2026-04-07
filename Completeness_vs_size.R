library(readxl)
library(tidyverse)

comp_file  <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Merged_completeness.xlsx"
gsize_file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Genome_size_sum.xlsx"

comp <- read_excel(comp_file) %>%
  rename(Sample = Name)

gsize <- read_excel(gsize_file) %>%
  rename(Sample = Name)

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

df <- comp_long %>%
  left_join(gsize_long, by = c("Sample", "Method")) %>%
  mutate(
    Genome_Size_Mb = Genome_Size / 1e6,
    Method = factor(
      Method,
      levels = c(
        "Illumina",
        "Nanopore",
        "Nanopore_racon",
        "Nanopore_medaka",
        "Nanopore_homopolisher",
        "Nanopore_racon_medaka",
        "Nanopore_medaka_homopolisher",
        "Hybrid"
      )
    )
  )

# remove missing values if any
df_clean <- df %>%
  filter(!is.na(Completeness), !is.na(Genome_Size_Mb))

# overall correlation
overall_spearman <- cor.test(
  df_clean$Genome_Size_Mb,
  df_clean$Completeness,
  method = "spearman"
)

overall_pearson <- cor.test(
  df_clean$Genome_Size_Mb,
  df_clean$Completeness,
  method = "pearson"
)

print(overall_spearman)
print(overall_pearson)

# per-method correlations
method_cor <- df_clean %>%
  group_by(Method) %>%
  summarise(
    n = n(),
    spearman_rho = cor(Genome_Size_Mb, Completeness, method = "spearman"),
    pearson_r = cor(Genome_Size_Mb, Completeness, method = "pearson"),
    .groups = "drop"
  )

print(method_cor)

# more complete per-method test with p-values
method_tests <- df_clean %>%
  group_by(Method) %>%
  group_modify(~{
    spearman_test <- cor.test(.x$Genome_Size_Mb, .x$Completeness, method = "spearman")
    pearson_test  <- cor.test(.x$Genome_Size_Mb, .x$Completeness, method = "pearson")
    
    tibble(
      n = nrow(.x),
      spearman_rho = unname(spearman_test$estimate),
      spearman_p = spearman_test$p.value,
      pearson_r = unname(pearson_test$estimate),
      pearson_p = pearson_test$p.value
    )
  }) %>%
  ungroup()

print(method_tests)

# overall scatter plot
p1 <- ggplot(df_clean, aes(x = Genome_Size_Mb, y = Completeness)) +
  geom_point(aes(color = Method), alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  labs(
    title = "Correlation between genome size and completeness",
    x = "Genome size (Mb)",
    y = "Completeness (%)"
  ) +
  theme_bw(base_size = 12)

print(p1)

# faceted scatter plot by method
p2 <- ggplot(df_clean, aes(x = Genome_Size_Mb, y = Completeness)) +
  geom_point(alpha = 0.75, size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 0.7) +
  facet_wrap(~ Method, scales = "free_x") +
  labs(
    title = "Genome size vs completeness by assembly method",
    x = "Genome size (Mb)",
    y = "Completeness (%)"
  ) +
  theme_bw(base_size = 12)

print(p2)

# optional: save results
# write.csv(method_tests, "genome_size_completeness_correlation_by_method.csv", row.names = FALSE)
# ggsave("genome_size_vs_completeness_overall.png", p1, width = 8, height = 6, dpi = 300)
# ggsave("genome_size_vs_completeness_by_method.png", p2, width = 12, height = 6, dpi = 300)