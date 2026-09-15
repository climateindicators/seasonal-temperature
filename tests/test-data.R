# Regression checks on the generated data for the Seasonal Temperature indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 3 dataset(s)", length(meta$datasets) == 3L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
f1 <- rd("seasonal_temperature_annual_anomaly.csv")
check("fig1: 512 rows (128 years x 4 seasons)", nrow(f1) == 512L)
check("fig1: first row is 1896 Winter 0.51",
      identical(as.list(f1[1, ]), list(year = "1896", season = "Winter", value = "0.51")))
check("fig1: last row is 2023 Fall 2.5",
      identical(as.list(f1[nrow(f1), ]), list(year = "2023", season = "Fall", value = "2.5")))
check("fig1: minimum value is 1979 Winter -5.62",
      identical(f1$value[which.min(as.numeric(f1$value))], "-5.62"))
check("fig1: maximum value is 2012 Spring 5.26",
      identical(f1$value[which.max(as.numeric(f1$value))], "5.26"))

f2 <- rd("seasonal_temperature_change_by_state.csv")
check("fig2: 192 rows (48 states x 4 seasons)", nrow(f2) == 192L)
check("fig2: first row is AL Winter 1.16784157",
      identical(as.list(f2[1, ]), list(state = "AL", season = "Winter", value = "1.16784157")))
check("fig2: last row is WY Fall 2.173510174",
      identical(as.list(f2[nrow(f2), ]), list(state = "WY", season = "Fall", value = "2.173510174")))
check("fig2: minimum value is AL Summer -0.462790698",
      identical(f2$value[which.min(as.numeric(f2$value))], "-0.462790698"))
check("fig2: maximum value is ND Winter 5.663117733",
      identical(f2$value[which.max(as.numeric(f2$value))], "5.663117733"))

f3 <- rd("seasonal_temperature_total_change_by_season.csv")
check("fig3: 4 rows (one per season)", nrow(f3) == 4L)
check("fig3: Winter total change is 2.943982558139536",
      identical(f3$value[f3$season == "Winter"], "2.943982558139536"))
check("fig3: Fall total change is 1.5887863372093023",
      identical(f3$value[f3$season == "Fall"], "1.5887863372093023"))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
