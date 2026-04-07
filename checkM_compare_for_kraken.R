library(tidyverse)

folder <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/CheckM_sum"

before_file <- file.path(folder, "nanopore_quality_report.tsv")
after_file  <- file.path(folder, "nanopore_after_kraken_quality_report.tsv")

extract_sample <- function(x) {
  str_extract(x, "^i[0-9]+_[0-9]+_barcode[0-9]+")
}

before <- read.delim(before_file, sep = "\t", check.names = FALSE) %>%
  mutate(
    Sample = extract_sample(Name)
  ) %>%
  select(Sample, Completeness, Contamination, Contig_N50, Average_Gene_Length) %>%
  mutate(
    Completeness = as.numeric(Completeness),
    Contamination = as.numeric(Contamination),
    Contig_N50 = as.numeric(Contig_N50),
    Average_Gene_Length = as.numeric(Average_Gene_Length)
  ) %>%
  rename(
    Completeness_before = Completeness,
    Contamination_before = Contamination,
    N50_before = Contig_N50,
    Length_before = Average_Gene_Length
  )

after <- read.delim(after_file, sep = "\t", check.names = FALSE) %>%
  mutate(
    Sample = extract_sample(Name)
  ) %>%
  select(Sample, Completeness, Contamination, Contig_N50, Average_Gene_Length) %>%
  mutate(
    Completeness = as.numeric(Completeness),
    Contamination = as.numeric(Contamination),
    Contig_N50 = as.numeric(Contig_N50),
    Average_Gene_Length = as.numeric(Average_Gene_Length)
  ) %>%
  rename(
    Completeness_after = Completeness,
    Contamination_after = Contamination,
    N50_after = Contig_N50,
    Length_after = Average_Gene_Length
  )

df <- inner_join(before, after, by = "Sample")

cat("Matched rows after join:", nrow(df), "\n")

df <- df %>%
  mutate(
    delta_completeness = Completeness_after - Completeness_before,
    delta_contamination = Contamination_after - Contamination_before,
    delta_N50 = N50_after - N50_before,
    delta_length = Length_after - Length_before
  )

# paired Wilcoxon tests
cat("\nCompleteness:\n")
print(wilcox.test(df$Completeness_before, df$Completeness_after, paired = TRUE))

cat("\nContamination:\n")
print(wilcox.test(df$Contamination_before, df$Contamination_after, paired = TRUE))

cat("\nN50:\n")
print(wilcox.test(df$N50_before, df$N50_after, paired = TRUE))

cat("\nAverage gene length:\n")
print(wilcox.test(df$Length_before, df$Length_after, paired = TRUE))

# summary of changes
summary_df <- df %>%
  summarise(
    mean_delta_completeness = mean(delta_completeness, na.rm = TRUE),
    mean_delta_contamination = mean(delta_contamination, na.rm = TRUE),
    mean_delta_N50 = mean(delta_N50, na.rm = TRUE),
    mean_delta_length = mean(delta_length, na.rm = TRUE)
  )

print(summary_df)

# scatter plots
plot_scatter <- function(data, x, y, title, xlab, ylab) {
  ggplot(data, aes(x = .data[[x]], y = .data[[y]])) +
    geom_point() +
    geom_abline(slope = 1, intercept = 0, color = "red") +
    labs(title = title, x = xlab, y = ylab) +
    theme_bw()
}

p1 <- plot_scatter(df, "Completeness_before", "Completeness_after",
                   "Completeness: before vs after Kraken", "Before", "After")

p2 <- plot_scatter(df, "Contamination_before", "Contamination_after",
                   "Contamination: before vs after Kraken", "Before", "After")

p3 <- plot_scatter(df, "N50_before", "N50_after",
                   "N50: before vs after Kraken", "Before", "After")

p4 <- plot_scatter(df, "Length_before", "Length_after",
                   "Average gene length: before vs after Kraken", "Before", "After")

print(p1)
print(p2)
print(p3)
print(p4)