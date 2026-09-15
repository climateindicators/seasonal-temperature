# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-seasonal-temperature/index.html>  \
  sha256 `44cf1f95c2b0858b6472857eb5218e1d6bc145313d1e32fc39a0caa35bd43465`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/seasonal-temperature_documentation.pdf>

## Figure data

- **Figures 1 and 3** have no data download on EPA's page, because EPA renders both as JavaScript charts with no download link and no chart `dataUrl`. Their data comes instead from EPA's own source workbook, added directly to this directory (not fetched by the build script):

  `seasonal temperature - Figures 1 and 3 - 01-29-24.xlsx`  \
  sha256 `7a93cb53853a6fee9e3407f04c8940b7fc55797a63435b2ef206e0bc668a59ce`  \
  sheets used: `Data for Figure 1` (128 years x 4 seasons, Year + Anomaly (degrees F) per season block), `Data for Figure 3` (4 rows, Season + 1896-2023 total change (degF))  \
  per the workbook's own `Methods and Notes` sheet: NOAA National Centers for Environmental Information (nClimDiv, CONUS averages), downloaded by ERG from noaa.gov/cag on 2024-02-13

- `seasonal-temperature_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/seasonal-temperature_fig-2.csv>  \
  sha256 `a8243a5f7a0760e5504f28c34a9323dcca020c6b3d5b9c4b1e22b9d68f3afd87`  \
  encoding UTF-8-BOM, 48 data rows, columns: `State`, `Winter`, `Spring`, `Summer`, `Fall`  \
  title: Figure 2. Change in Seasonal Temperatures by State, 1896–2023  \
  data source: NOAA, 2024; web update: June 2024; units: total change (degrees F)

  A second workbook, `seasonal temperature - Figure 2 - 02-13-24.xlsx` (sha256 `afe67eae6fac89ce99839d1d793857097701b66f02da33c4f6d6483fc7a90994`), was also added to this directory. It carries the same Figure 2 data in a different (state-as-column) layout and is kept here for reference only; the build reads the CSV above instead, since that one is EPA's own direct-download file for this figure.
