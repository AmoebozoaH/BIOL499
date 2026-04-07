# Install once if needed
# install.packages(c("readr", "readxl", "writexl", "tools"))

library(readr)
library(writexl)
library(tools)

# Folder containing your CheckM reports
input_dir <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/CheckM_sum"

# Find all csv and tsv files
files <- list.files(
  path = input_dir,
  pattern = "\\.(csv|tsv)$",
  full.names = TRUE,
  ignore.case = TRUE
)

print(files)

# Function to convert one file
convert_to_xlsx <- function(f) {
  ext <- tolower(file_ext(f))
  
  # Read file based on extension
  dat <- switch(
    ext,
    "csv" = read_csv(f, show_col_types = FALSE),
    "tsv" = read_tsv(f, show_col_types = FALSE),
    stop(paste("Unsupported file type:", f))
  )
  
  # Create output file name
  out_file <- file.path(
    dirname(f),
    paste0(file_path_sans_ext(basename(f)), ".xlsx")
  )
  
  # Write xlsx
  write_xlsx(dat, out_file)
  
  message("Converted: ", basename(f), " -> ", basename(out_file))
}

# Convert all files
invisible(lapply(files, convert_to_xlsx))

message("Done.")