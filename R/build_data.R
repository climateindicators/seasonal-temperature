# Build tidy long-format data for the Seasonal Temperature indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
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

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

FIG2_COLUMNS <- list(
  col("state", "character", "Two-letter U.S. state postal code (contiguous 48 states only)."),
  col("season", "character", "Meteorological season: Winter (Dec-Feb), Spring (Mar-May), Summer (Jun-Aug), or Fall (Sep-Nov)."),
  col("value", "numeric", "Total change in average seasonal temperature, 1896-2023, in degrees Fahrenheit.")
)

meta <- list(
  indicator = INDICATOR,
  datasets = list(
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
