suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
})

illumina_file <- "C:\\Users\\Amoeb\\Documents\\ZSW2025-2026\\Waterloo_courses\\BIOL499A\\nanopore\\Raw_data\\illumina_raw\\fastqc_results\\multiqc_report\\multiqc_data\\multiqc_fastqc.txt"
nanopore_file <- "C:\\Users\\Amoeb\\Documents\\ZSW2025-2026\\Waterloo_courses\\BIOL499A\\nanopore\\Raw_data\\nanopore_raw\\fastqc_results\\multiqc_report\\multiqc_data\\multiqc_fastqc.txt"

genome_size_bp <- 2046572 #extracted from reference using seqkit stats

output_dir <- "C:\\Users\\Amoeb\\Documents\\ZSW2025-2026\\Waterloo_courses\\BIOL499A\\nanopore\\Raw_data\\"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

output_table <- file.path(output_dir, "platform_summary_from_multiqc_fastqc.tsv")
output_plot_pdf <- file.path(output_dir, "platform_ABC_from_multiqc_fastqc.pdf")
output_plot_png <- file.path(output_dir, "platform_ABC_from_multiqc_fastqc.png")

required_columns <- c("Sample", "Total Sequences", "avg_sequence_length")

check_required_cols <- function(df) {
  missing <- setdiff(required_columns, colnames(df))
  if (length(missing) > 0) {
    stop(
      paste0(
        "Missing required columns: ",
        paste(missing, collapse = ", "),
        "\nAvailable columns are:\n",
        paste(colnames(df), collapse = ", ")
      )
    )
  }
}

simplify_illumina_name <- function(x) {
  x |>
    str_replace("\\.fastq\\.gz$", "") |>
    str_replace("\\.fq\\.gz$", "") |>
    str_replace("_R1_001$", "") |>
    str_replace("_R2_001$", "")
}

simplify_nanopore_name <- function(x) {
  x |>
    str_replace("\\.fastq\\.gz$", "") |>
    str_replace("\\.fq\\.gz$", "")
}

parse_total_bases <- function(x) {
  x <- str_trim(as.character(x))
  value <- suppressWarnings(as.numeric(str_extract(x, "^[0-9.]+")))
  unit <- str_extract(x, "(?i)([KMGTP]?)bp$")
  
  multiplier <- case_when(
    is.na(unit) ~ 1,
    str_to_lower(unit) == "kbp" ~ 1e3,
    str_to_lower(unit) == "mbp" ~ 1e6,
    str_to_lower(unit) == "gbp" ~ 1e9,
    str_to_lower(unit) == "tbp" ~ 1e12,
    TRUE ~ 1
  )
  
  value * multiplier
}

make_panel_plot <- function(df, yvar, ylab, panel_label) {
  ggplot(df, aes(x = platform, y = .data[[yvar]], fill = platform)) +
    geom_violin(trim = FALSE, alpha = 0.45, width = 0.8, color = "black") +
    geom_jitter(aes(shape = platform),
                width = 0.10, size = 2.2, alpha = 0.85, color = "black"
    ) +
    stat_summary(
      fun = median,
      fun.min = median,
      fun.max = median,
      geom = "crossbar",
      width = 0.35,
      linewidth = 0.4,
      color = "black"
    ) +
    scale_fill_manual(values = c("Illumina" = "#ec6060", "Nanopore" = "#78c16d")) +
    scale_shape_manual(values = c("Illumina" = 16, "Nanopore" = 15)) +
    labs(x = NULL, y = ylab) +
    annotate("text", x = 0.6, y = Inf, label = panel_label,
             vjust = 1.5, hjust = 0, fontface = "bold", size = 6
    ) +
    theme_classic(base_size = 14) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(face = "bold", size = 16),
      axis.title.y = element_text(face = "bold"),
      plot.margin = margin(10, 15, 10, 20)
    )
}

read_and_prepare <- function(file_path, platform_type) {
  df <- read_tsv(file_path, show_col_types = FALSE)
  check_required_cols(df)
  
  keep_cols <- intersect(
    c("Sample", "Filename", "Total Sequences", "Total Bases", "avg_sequence_length"),
    colnames(df)
  )
  
  df <- df |> select(all_of(keep_cols))
  
  has_total_bases <- "Total Bases" %in% colnames(df)
  
  if (platform_type == "Illumina") {
    df <- df |>
      mutate(
        Sample = simplify_illumina_name(Sample),
        total_reads = as.numeric(`Total Sequences`),
        avg_read_length = as.numeric(avg_sequence_length)
      )
    
    if (has_total_bases) {
      df <- df |>
        mutate(total_bases = parse_total_bases(`Total Bases`))
    } else {
      df <- df |>
        mutate(total_bases = total_reads * avg_read_length)
    }
    
    df <- df |>
      mutate(total_bases = ifelse(is.na(total_bases), total_reads * avg_read_length, total_bases)) |>
      group_by(Sample) |>
      summarise(
        total_reads = sum(total_reads, na.rm = TRUE),
        total_bases = sum(total_bases, na.rm = TRUE),
        avg_read_length = total_bases / total_reads,
        depth_x = (total_reads * avg_read_length) / genome_size_bp,
        .groups = "drop"
      ) |>
      mutate(platform = "Illumina")
  }
  
  if (platform_type == "Nanopore") {
    df <- df |>
      mutate(
        Sample = simplify_nanopore_name(Sample),
        total_reads = as.numeric(`Total Sequences`),
        avg_read_length = as.numeric(avg_sequence_length)
      )
    
    if (has_total_bases) {
      df <- df |>
        mutate(total_bases = parse_total_bases(`Total Bases`))
    } else {
      df <- df |>
        mutate(total_bases = total_reads * avg_read_length)
    }
    
    df <- df |>
      mutate(
        total_bases = ifelse(is.na(total_bases), total_reads * avg_read_length, total_bases),
        depth_x = (total_reads * avg_read_length) / genome_size_bp,
        platform = "Nanopore"
      ) |>
      select(Sample, total_reads, total_bases, avg_read_length, depth_x, platform)
  }
  
  df
}

illumina <- read_and_prepare(illumina_file, "Illumina")
nanopore <- read_and_prepare(nanopore_file, "Nanopore")

combined <- bind_rows(illumina, nanopore) |>
  mutate(platform = factor(platform, levels = c("Illumina", "Nanopore")))

write_tsv(combined, output_table)

plot_A <- make_panel_plot(combined, "depth_x", "Sequencing Depth (X)", "A.")
plot_B <- make_panel_plot(combined, "total_reads", "Number of Reads", "B.")
plot_C <- make_panel_plot(combined, "avg_read_length", "Average Read Length (bp)", "C.")

combined_plot <- plot_A + plot_B + plot_C + plot_layout(ncol = 3)

print(combined_plot)

ggsave("C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/Writeup/Plot_collection/Figure1_Multiqc.png", 
         plot = plot_A,
         width = 11.64,
         height = 10,
         units = "in",
         dpi = 300)