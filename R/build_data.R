# Build tidy long-format data for the Seasonal Temperature indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs and source workbook in data-raw/ and writes
# data/*.csv plus data/meta.yml. Rerunning with unchanged inputs produces
# byte-identical output. Nothing here touches the network.
#
# Figure 2 has a CSV download on EPA's page. Figures 1 and 3 do not (EPA
# renders them as JavaScript charts with no underlying data file), so their
# data comes from EPA's own source workbook instead, added directly to
# data-raw/: "seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx".
#
# TO UPDATE THE DATA: drop replacement files into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Seasonal Temperature",
  slug                    = "seasonal-temperature",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-seasonal-temperature/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/seasonal-temperature_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: average seasonal temperature anomaly, 1896-2023 --------------
#
# EPA's published page renders this as a JavaScript chart with no CSV download
# (confirmed: neither a download link nor a chart dataUrl). The data instead
# comes from EPA's own source workbook, added directly to data-raw/. Its
# "Methods and Notes" sheet documents the chain: NOAA's nClimDiv CONUS
# averages, downloaded by ERG from noaa.gov/cag on 2024-02-13.

f1_path  <- file.path(raw_dir, "seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx")
f1_sheet <- "Data for Figure 1"
SEASONS_F1 <- c("Winter", "Spring", "Summer", "Fall")

# The sheet lays out four season blocks side by side (Year, Anomaly), each
# under its own season label one row above the column header. Both rows are
# asserted so a reordered or relabelled block stops the build.
f1_season_row <- suppressMessages(read_excel(f1_path, sheet = f1_sheet, n_max = 1, col_names = FALSE))
stopifnot(
  "figure 1: expects 4 season blocks in Winter, Spring, Summer, Fall order" =
    identical(toupper(trimws(as.character(f1_season_row[1, c(1, 3, 5, 7)]))), toupper(SEASONS_F1))
)

f1_header_row <- suppressMessages(read_excel(f1_path, sheet = f1_sheet, skip = 1, n_max = 1, col_names = FALSE))
stopifnot(
  "figure 1: expects a Year / Anomaly (degrees F) pair per season block" =
    identical(as.character(f1_header_row[1, ]), rep(c("Year", "Anomaly (degrees F)"), 4))
)

f1_raw <- suppressMessages(read_excel(f1_path, sheet = f1_sheet, skip = 2, col_names = FALSE, col_types = "text"))
stopifnot("figure 1: expects 8 columns (4 seasons x Year/Anomaly)" = ncol(f1_raw) == 8L)

f1 <- do.call(rbind, lapply(seq_along(SEASONS_F1), function(i) {
  yr_col  <- (i - 1L) * 2L + 1L
  val_col <- yr_col + 1L
  data.frame(
    year   = as.integer(f1_raw[[yr_col]]),
    season = SEASONS_F1[i],
    # Anomalies are hundredths-of-a-degree data. The workbook stores them as
    # IEEE-754 doubles, so a value entered as 0.14 can come back as
    # "0.14000000000000001": round(x, 2) clears that noise. Verified lossless
    # first: every one of the 512 source values round-trips exactly through
    # round(x, 2) (max deviation 0), so nothing is lost, only the noise.
    value  = as.character(round(as.numeric(f1_raw[[val_col]]), 2)),
    stringsAsFactors = FALSE
  )
}))
f1 <- f1[order(f1$year, match(f1$season, SEASONS_F1)), ]
rownames(f1) <- NULL

stopifnot(
  "figure 1: years should be contiguous 1896-2023 for every season" =
    identical(sort(unique(f1$year)), seq(1896L, 2023L)),
  "figure 1: expects exactly 128 years x 4 seasons" = nrow(f1) == 512L
)

write_csv_stable(f1, file.path(out_dir, "seasonal_temperature_annual_anomaly.csv"))

# ---- Figure 2: Change in Seasonal Temperatures by State, 1896–2023 ----

f2_path <- file.path(raw_dir, "seasonal-temperature_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f2_raw,
  id_cols          = character(),
  expected_headers = c("State", "Winter", "Spring", "Summer", "Fall"),
  what             = "seasonal-temperature_fig-2.csv"
)

SEASONS <- c("Winter", "Spring", "Summer", "Fall")

f2 <- f2_raw |>
  dplyr::rename(state = State) |>
  tidyr::pivot_longer(
    cols      = dplyr::all_of(SEASONS),
    names_to  = "season",
    values_to = "value"
  ) |>
  dplyr::filter(trimws(value) != "") |>
  dplyr::arrange(state, match(season, SEASONS))

assert_conservation(f2_raw, SEASONS, nrow(f2), "seasonal-temperature_fig-2.csv")

write_csv_stable(f2, file.path(out_dir, "seasonal_temperature_change_by_state.csv"))

# ---- Figure 3: total change in temperature by season, 1896-2023 -------------
#
# Same "no CSV on the page" situation as Figure 1; same source workbook, its
# "Data for Figure 3" sheet.

f3_path  <- file.path(raw_dir, "seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx")
f3_sheet <- "Data for Figure 3"

f3_raw <- read_excel(f3_path, sheet = f3_sheet, col_types = c("text", "text"))
stopifnot(
  "figure 3: expects Season + 1896-2023 total change (degF) columns" =
    identical(names(f3_raw), c("Season", "1896-2023 total change (degF)")),
  "figure 3: expects one row per season" = nrow(f3_raw) == 4L,
  "figure 3: expects Winter, Spring, Summer, Fall in that order" =
    identical(f3_raw$Season, c("Winter", "Spring", "Summer", "Fall"))
)

# Kept at full source precision (unlike Figure 1): this is a computed total
# change, not a rounded annual reading, so nothing here is float noise.
f3 <- data.frame(
  season = f3_raw$Season,
  value  = f3_raw[["1896-2023 total change (degF)"]],
  stringsAsFactors = FALSE
)

write_csv_stable(f3, file.path(out_dir, "seasonal_temperature_total_change_by_season.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

NOAA_WORKBOOK_SOURCE <- paste(
  "NOAA National Centers for Environmental Information (nClimDiv, CONUS averages),",
  "via EPA source workbook; downloaded by ERG from noaa.gov/cag on 2024-02-13"
)

FIG1_COLUMNS <- list(
  col("year", "integer", "Year a season falls in (winter is assigned to the year it ends in, e.g. Dec 2015-Feb 2016 is winter 2016)."),
  col("season", "character", "Meteorological season: Winter (Dec-Feb), Spring (Mar-May), Summer (Jun-Aug), or Fall (Sep-Nov)."),
  col("value", "numeric", "Average seasonal temperature anomaly vs. the 1901-2000 average, in degrees Fahrenheit.")
)

FIG2_COLUMNS <- list(
  col("state", "character", "Two-letter U.S. state postal code (contiguous 48 states only)."),
  col("season", "character", "Meteorological season: Winter (Dec-Feb), Spring (Mar-May), Summer (Jun-Aug), or Fall (Sep-Nov)."),
  col("value", "numeric", "Total change in average seasonal temperature, 1896-2023, in degrees Fahrenheit.")
)

FIG3_COLUMNS <- list(
  col("season", "character", "Meteorological season: Winter (Dec-Feb), Spring (Mar-May), Summer (Jun-Aug), or Fall (Sep-Nov)."),
  col("value", "numeric", "Total change in average seasonal temperature across the contiguous 48 states, 1896-2023, in degrees Fahrenheit.")
)

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "seasonal_temperature_annual_anomaly.csv",
      figure          = "Figure 1",
      figure_title    = "Figure 1",
      source_file     = "seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "xlsx",
      data_source     = NOAA_WORKBOOK_SOURCE,
      web_update      = NA,
      unit            = "degrees F (anomaly vs. 1901-2000 average)",
      rows            = nrow(f1),
      columns         = FIG1_COLUMNS
    ),
    list(
      file            = "seasonal_temperature_change_by_state.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "seasonal-temperature_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2),
      columns         = FIG2_COLUMNS
    ),
    list(
      file            = "seasonal_temperature_total_change_by_season.csv",
      figure          = "Figure 3",
      figure_title    = "Figure 3",
      source_file     = "seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx",
      source_sha256   = file_sha256(f3_path),
      source_encoding = "xlsx",
      data_source     = NOAA_WORKBOOK_SOURCE,
      web_update      = NA,
      unit            = "degrees F (total change, 1896-2023)",
      rows            = nrow(f3),
      columns         = FIG3_COLUMNS
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
