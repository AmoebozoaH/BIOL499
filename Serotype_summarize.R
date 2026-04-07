# Install once if needed:
# install.packages(c("readxl", "tidyverse"))

library(readxl)
library(tidyverse)

# ---- 1) Read the Excel file ----
df <- read_excel("C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Serotype_sum.xlsx")

# ---- 2) Make duplicate column names unique ----
# This is important because you have several "Nanopore" columns
names(df) <- make.unique(names(df))

# Check names
print(names(df))

# ---- 3) Rename first column if needed ----
# Assuming first column is sample ID
names(df)[1] <- "Sample"

# ---- 4) Convert to long format ----
df_long <- df %>%
  pivot_longer(
    cols = -Sample,
    names_to = "Method",
    values_to = "Serotype"
  )

# ---- 5) Keep original order from spreadsheet ----
df_long$Sample <- factor(df_long$Sample, levels = rev(df$Sample))
df_long$Method <- factor(df_long$Method, levels = names(df)[-1])

# ---- 6) Heatmap ----
p <- ggplot(df_long, aes(x = Method, y = Sample, fill = Serotype)) +
  geom_tile(color = "white", linewidth = 0.3) +
  geom_text(aes(label = Serotype), size = 3) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    axis.title = element_blank()
  ) +
  labs(fill = "Serotype")

print(p)