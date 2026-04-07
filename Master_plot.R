# requirement: .tree file and ready_for_R_plot.csv from meta_pathogen_merge_submit_version.ipynb place under target pathogewatch directory

setwd("C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/nanopore_medaka_polypolisher_pypolca/Pathogenwatch/")

suppressPackageStartupMessages({
  library(ape)
  library(ggplot2)
  library(ggtree)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(viridisLite)
  library(readr)
  library(aplot)
})

## import files
tr <- ape::read.tree("C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/nanopore_medaka_polypolisher_pypolca/tree_output/RAxML_bipartitions_renamed.spn_tree")
meta <- readr::read_csv("ready_for_R_plot_final.csv", show_col_types = FALSE)

## plot the tree
p_tree <- ggtree(tr) + theme_tree2()

# set tip location
tip_df <- p_tree$data %>%
  filter(isTip) %>%
  select(label, x, y)

# find max branch and offset
xmax <- max(p_tree$data$x, na.rm = TRUE)
offset <- 0.02 * xmax
x_end <- xmax + offset

# add dash line to the tree
p_tree <- p_tree +
  geom_segment(
    data = tip_df,
    aes(x = x, xend = x_end, y = y, yend = y),
    inherit.aes = FALSE,
    linetype = "dashed",
    linewidth = 0.3
  ) +
  geom_text(  # add the text
    data = tip_df,
    aes(x = x_end, y = y, label = label),
    inherit.aes = FALSE,
    hjust = 0,
    size = 2
  ) +
  coord_cartesian(xlim = c(NA, x_end + offset)) +
  theme(
    axis.title = element_blank(),
    axis.text  = element_blank(),
    axis.ticks = element_blank(),
    axis.line  = element_blank()
  ) +
  geom_point2(                        # add point at node where confidance is >= 90
    aes(
      subset = !isTip & as.numeric(label) >= 90,
      shape = "Bootstrap ≥ 90"
    ),
    size = 1.5
  ) +
  scale_shape_manual(                 # add legend for point
    name = "Node support",
    values = c("Bootstrap ≥ 90" = 16)  # filled circle
  ) +
  theme(                                  # adjust margin of plot
    plot.margin = margin(5.5, 30, 5.5, 0)  # top, right, bottom, left
  )

# obtain tip location to add heatmap
tip_pos <- tip_df %>% select(label, y)

#################################################

## metadata columns
# with label, no color
label_fields <- c("Serotype", "mlst")

# with color,and legend
hm2a_fields <- c( 
                 "Ceftriaxone", 
                 "Clindamycin",
                 "Erythromycin",
                 "Levofloxacin",
                 "Penicillin",
                 "Tetracycline",
                 "Vancomycin"
                 )
hm2b_fields <- c("Amoxicillin_adjusted",
                 "Cefotaxime_adjusted",
                 "Ceftriaxone_adjusted",
                 "Meropenem_adjusted",
                 "Penicillin_adjusted",
                 "NP swap/ear swap")

# with color, and ledgend, and value
age <- c("ageInMonths", "Genome_Completeness")

###############################################

## join tree y position with metadata
joined <- tip_pos %>%
  left_join(meta, by = c("label" = "Index"))

## shared y limits (with padding)
yr <- range(tip_pos$y)
pad <- 2
ylims <- c(yr[1] - pad, yr[2] + pad)

p_tree <- p_tree + scale_y_continuous(limits = ylims, expand = c(0, 0))  # fix the tree aligning with heatmap

## Heatmap 1: labeled columns (grey tiles + text)
hm1_long <- joined %>%
  pivot_longer(
    cols = all_of(label_fields),
    names_to = "field",
    values_to = "value",
    values_transform = list(value = as.character)
  ) %>%
  mutate(
    field = factor(field, levels = label_fields),
    text_label = as.character(value),
    text_label = if_else(is.na(text_label), "", text_label),
    text_label = if_else(nchar(text_label) > 14, "New", text_label),
    fill_val = as.factor(value)
  )

p_hm1 <- ggplot(hm1_long, aes(x = field, y = y)) +
  geom_tile(aes(fill = fill_val), color = "white", linewidth = 0.2) +
  geom_text(aes(label = text_label), size = 2) +
  scale_y_continuous(limits = ylims, expand = c(0, 0)) +
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, vjust = 1.3, hjust = 1),
    legend.position = "none",
    plot.margin = margin(5.5, 0, 5.5, 0)
  )

## Heatmap 2: color-only columns (colored tiles, no text)
hm2a_long <- joined %>%
  pivot_longer(
    cols = all_of(hm2a_fields),
    names_to = "field",
    values_to = "value"
  ) %>%
  mutate(
    field = factor(field, levels = hm2a_fields),
    fill_val = as.factor(value)
  )

p_hm2a <- ggplot(hm2a_long, aes(x = field, y = y, fill = fill_val)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_fill_manual(
    name = "",
    values = c(
      "R" = "#DD6E42",
      "S" = "#4F6D7A",
      "I" = "#E9C46A"
    ),
    na.value = "grey90"
  ) +
  scale_y_continuous(limits = ylims, expand = c(0, 0)) +
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, vjust = 1.3, hjust = 1),
    plot.margin = margin(5.5, 0, 5.5, 0),
    legend.position = "none"
  )


hm2b_long <- joined %>%
  pivot_longer(
    cols = all_of(hm2b_fields),
    names_to = "field",
    values_to = "value"
  ) %>%
  mutate(
    field = factor(field, levels = hm2b_fields),
    fill_val = as.factor(value)
  )

p_hm2b <- ggplot(hm2b_long, aes(x = field, y = y, fill = fill_val)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_fill_manual(
    name = "",
    values = c(
      "R" = "#DD6E42",
      "S" = "#4F6D7A",
      "I" = "#E9C46A",
      "NP" = "#FAF0CA",
      "Ear" = "#0D3B66"
    ),
    breaks = c("S", "I", "R", "NP", "Ear"), 
    labels = c(
      "R" = "Resistance",
      "S" = "Susceptible",
      "I" = "Intermediate",
      "NP" = "Nose Swap",
      "Ear" = "Ear Swap"
    ),
    na.value = "grey90"
  ) +
  scale_y_continuous(limits = ylims, expand = c(0, 0)) +
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, vjust = 1.3, hjust = 1),
    plot.margin = margin(5.5, 5.5, 5.5, 0),
    theme(legend.position = "none")
  )

## Heatmap 3a: Age (months)
age_long <- joined %>%
  transmute(
    y,
    field = "Age (months)",
    value = as.numeric(ageInMonths)
  ) %>%
  mutate(
    txt_col = ifelse(value <= 18, "white", "black")
  )

age_hm <- ggplot(age_long, aes(x = field, y = y, fill = value)) +
  geom_tile(color = NA, linewidth = 0.0) +
  geom_text(
    aes(
      label = ifelse(is.na(value), "", round(value, 1)),
      color = txt_col
    ),
    size = 2.2
  ) +
  scale_color_identity() +
  scale_fill_viridis_c(
    name = "Age (months)",
    na.value = "grey90"
  ) +
  scale_y_continuous(limits = ylims, expand = c(0, 0)) +
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, vjust = 1.3, hjust = 1),
    plot.margin = margin(5.5, 0, 5.5, 0)
  )

## Heatmap 3b: Genome Completeness (%)
gc_long <- joined %>%
  transmute(
    y,
    field = "Genome Completeness (%)",
    value = as.numeric(Genome_Completeness)
  ) %>%
  mutate(
    txt_col = ifelse(value >= 90, "white", "black")
  )

gc_hm <- ggplot(gc_long, aes(x = field, y = y, fill = value)) +
  geom_tile(color = NA, linewidth = 0.25) +
  geom_text(
    aes(
      label = ifelse(is.na(value), "", round(value, 1)),
      color = txt_col
    ),
    size = 2.2
  ) +
  scale_color_identity() +
  scale_fill_gradient(
    name = "Genome Completeness (%)",
    low = "#f2f2f2",
    high = "#08306b",
    na.value = "grey90"
  ) +
  scale_y_continuous(limits = ylims, expand = c(0, 0)) +
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, vjust = 1.3, hjust = 1),
    plot.margin = margin(5.5, 0, 5.5, 0)
  )

panel_width <- function(n_cols, unit = 0.0555) {
  n_cols * unit
}

## merge heatmaps to tree
p_combined <- p_tree %>%
  aplot::insert_right(p_hm1,  width = panel_width(length(label_fields))) %>%
  aplot::insert_right(p_hm2a, width = panel_width(length(hm2a_fields))) %>%
  aplot::insert_right(p_hm2b, width = panel_width(length(hm2b_fields))) %>%
  aplot::insert_right(age_hm, width = panel_width(1)) %>%
  aplot::insert_right(gc_hm,  width = panel_width(1))

print(p_combined)

