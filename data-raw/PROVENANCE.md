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

- **Figure 1** has no data download on EPA's page, because EPA renders it as a JavaScript chart. The narrative carries the caption; there is nothing to build.

- `seasonal-temperature_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/seasonal-temperature_fig-2.csv>  \
  sha256 `a8243a5f7a0760e5504f28c34a9323dcca020c6b3d5b9c4b1e22b9d68f3afd87`  \
  encoding UTF-8-BOM, 48 data rows, columns: `State`, `Winter`, `Spring`, `Summer`, `Fall`  \
  title: Figure 2. Change in Seasonal Temperatures by State, 1896–2023  \
  data source: NOAA, 2024; web update: June 2024; units: total change (degrees F)

- **Figure 3** has no data download on EPA's page, because EPA renders it as a JavaScript chart. The narrative carries the caption; there is nothing to build.
