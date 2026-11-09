# Pump and Prosper

STAT 231 Data Science Blog Project  
Amherst College, Fall 2026

**Authors:** Declan DuBois, Tetsuya Tanaka, and Zhi Heng Chen

## Project Overview

This project investigates the relationship between gasoline prices and economic conditions across U.S. states. We combine monthly gasoline prices, weekly earnings, weekly hours, unemployment rates, labor force participation rates, and Consumer Price Index (CPI) data.

The wrangling process produces cleaned, analysis-ready datasets for all 50 states, including inflation-adjusted gasoline prices and weekly earnings.

## Repository Structure

- `raw_data/` — Original datasets and data acquisition scripts.
- `wrangle_data/` — R script for cleaning and combining the raw datasets.
- `data/` — Final cleaned datasets ready for analysis.
- `index.qmd` — Quarto source file for the blog.
- `docs/` — Rendered website files for GitHub Pages.

## Reproducing the Data Wrangling

The complete wrangling pipeline is contained in:

`wrangle_data/complete_wrangled_data_declan_and_zhi.R`

The script reads the raw files from `raw_data/`, performs the necessary cleaning and transformations, and saves six datasets in `data/`.

### Requirements

The script requires R and the following packages:

- `tidyverse`
- `lubridate`

### Instructions

1. Open `blog-template.Rproj` in RStudio.
2. Run the following command in the RStudio Console:

```r
source(
  "wrangle_data/complete_wrangled_data_declan_and_zhi.R",
  chdir = TRUE
)
```


We use `chdir = TRUE` when sourcing the consolidated wrangling script so that relative file paths are interpreted from the script's directory rather than the current RStudio working directory. This allows the script to access the raw datasets and save the processed outputs consistently.

**Reference:** R Core Team. *R Documentation: source — Read R Code from a File, a Connection or Expressions.* https://stat.ethz.ch/R-manual/R-devel/library/base/html/source.html

The script uses the raw datasets already included in the repository.

### Output Datasets

The script generates six CSV files in `data/`:

- `weekly_earnings_all.csv`
- `weekly_hours_all.csv`
- `gas_real.csv`
- `unemployment_all.csv`
- `labor_force_participation_all.csv`
- `combined_data.csv`

The primary dataset, `combined_data.csv`, combines the relevant economic indicators and is imported directly into `index.qmd`.

Gasoline prices and weekly earnings are adjusted to September 2026 dollars using CPI data. Months without available CPI observations are excluded from the inflation-adjusted datasets.

## Contributions

- **Zhi Heng Chen:** Cleaned weekly earnings and hours data and drafted the consolidated wrangling script.
- **Declan DuBois:** Cleaned and inflation-adjusted gasoline prices and documented the wrangling process. Wrote this README. 
- **Tetsuya Tanaka:** Cleaned unemployment and labor force participation data and combined the datasets.

