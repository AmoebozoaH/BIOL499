# install.packages("readxl")
library(readxl)

file <- "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_sum.xlsx"

df <- read_excel(file)
colnames(df) <- make.unique(colnames(df))

reference <- "Clinical"
sample_col <- colnames(df)[1]

# Standardize values
for (i in seq_along(df)) {
  df[[i]] <- toupper(trimws(as.character(df[[i]])))
}

# Recode function: S = negative, I/R = positive
recode_binary <- function(x) {
  ifelse(x == "S", "NEG",
         ifelse(x %in% c("I", "R"), "POS", NA))
}

df[[reference]] <- recode_binary(df[[reference]])

methods <- setdiff(colnames(df), c(sample_col, reference))

results <- data.frame()

for (m in methods) {
  tmp <- df[, c(reference, m)]
  tmp[[m]] <- recode_binary(tmp[[m]])
  tmp <- tmp[complete.cases(tmp), ]
  
  TP <- sum(tmp[[reference]] == "POS" & tmp[[m]] == "POS")
  TN <- sum(tmp[[reference]] == "NEG" & tmp[[m]] == "NEG")
  FP <- sum(tmp[[reference]] == "NEG" & tmp[[m]] == "POS")
  FN <- sum(tmp[[reference]] == "POS" & tmp[[m]] == "NEG")
  
  sensitivity <- ifelse((TP + FN) > 0, TP / (TP + FN), NA)
  specificity <- ifelse((TN + FP) > 0, TN / (TN + FP), NA)
  accuracy <- ifelse((TP + TN + FP + FN) > 0, (TP + TN) / (TP + TN + FP + FN), NA)
  
  results <- rbind(results, data.frame(
    Method = m,
    TP = TP,
    TN = TN,
    FP = FP,
    FN = FN,
    Sensitivity = round(sensitivity, 3),
    Specificity = round(specificity, 3),
    Accuracy = round(accuracy, 3)
  ))
  
  cat("\n==============================\n")
  cat("Method:", m, "\n")
  print(table(Clinical = tmp[[reference]], Prediction = tmp[[m]]))
}

print(results)

write.csv(
  results,
  "C:/Users/Amoeb/Documents/ZSW2025-2026/Waterloo_courses/BIOL499A/nanopore/Plotting/Penicillin_binary_summary_IR_as_positive.csv",
  row.names = FALSE
)