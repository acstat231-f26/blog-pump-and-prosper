# This script turns the raw data in `raw_data/` into saved datasets in `data/`.
# It uses the files already in the repository, so rerunning it does not require
# an internet connection. The last section writes `combined_data.csv`,
# which is the dataset loaded by `index.qmd`.

# Contributions: 

# - Zhi Heng Chen cleaned weekly earnings and hours and wrote the draft consolidated wrangling file. 
# - Declan DuBois cleaned and inflation-adjusted gasoline prices and provided informative code comments throughout the document.  
# - Tetsuya Tanaka cleaned unemployment and labor-force participation data and combined the datasets.

library(tidyverse)
library(lubridate)

# Paths are relative to this script's location in wrangle_data/.
raw_dir <- "../raw_data"
data_dir <- "../data"


# Weekly earnings and hours — Zhi Heng Chen


# Combine monthly weekly-earnings observations for all states.

# Two-letter abbreviations for the 50 states.
state_initials <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

weekly_earnings_all <- tibble()

for (i in seq_along(state_initials)) {
  name <- state_initials[i]
  new_data <- read_csv(
    file.path(raw_dir, "weekly_earnings", paste0(name, ".csv")),
    show_col_types = FALSE) |>
    # Renames the columns
    rename(Date = 1, weekly_earnings = 2) |>
    mutate(State = name)
  weekly_earnings_all <- bind_rows(weekly_earnings_all, new_data)
}

# The CSV headers are already on the first line; do not skip January 2007.
# Split date into year and month.
weekly_earnings_all <- weekly_earnings_all |>
  mutate(Year = year(Date),
         Month = month(Date)) |>
  select(-Date)

# Adjust weekly earnings to September 2026 dollars
CPI <- read_csv(file.path(raw_dir, "CPIAUCNS.csv"),
                show_col_types = FALSE) |>
  mutate(Date = as.Date(observation_date),
         Year = year(Date),
         Month = month(Date))

# Use September 2026 as the common inflation-adjustment base.
CPI_base <- CPI |>
  filter(Date == as.Date("2026-09-01")) |>
  pull(CPIAUCNS)

# October 2025 CPI is unavailable in this source snapshot. Exclude that
# month from inflation-adjusted earnings instead of guessing a CPI value.
weekly_earnings_all <- weekly_earnings_all |>
  left_join(CPI |> select(Year, Month, CPIAUCNS), by = c("Year", "Month")) |>
  mutate(real_weekly_earnings = weekly_earnings * (CPI_base / CPIAUCNS)) |>
  filter(!is.na(CPIAUCNS)) |>
  select(-CPIAUCNS)

# Save the cleaned dataset so it can be imported without re-wrangling.
write_csv(weekly_earnings_all, file.path(data_dir, "weekly_earnings_all.csv"))


# Combine monthly weekly-hours observations for all states.
weekly_hours_all <- tibble()

for (i in seq_along(state_initials)) {
  name <- state_initials[i]
  new_data <- read_csv(
    file.path(raw_dir, "weekly_hours", paste0(name, ".csv")),
    show_col_types = FALSE) |>
    # Renames the columns
    rename(Date = 1, weekly_hours = 2) |>
    mutate(State = name)
  weekly_hours_all <- bind_rows(weekly_hours_all, new_data)
}

# These CSVs also have ordinary first-line headers; keep January 2007.
# Split date into year and month.
weekly_hours_all <- weekly_hours_all |>
  mutate(Year = year(Date),
         Month = month(Date)) |>
  select(-Date)

write_csv(weekly_hours_all, file.path(data_dir, "weekly_hours_all.csv"))


# Gasoline prices — Declan DuBois


# Read raw daily gasoline prices.
gas_raw <- read_csv(file.path(raw_dir, "MasterGas.csv"),
                    show_col_types = FALSE) |>
  rename(Mid.Grade = `Mid-Grade`)
# Convert dates and dollar strings to values.
gas_cleaned <- gas_raw |>
  mutate(
    Date = as.Date(Date),
    across(
      c(Regular, Mid.Grade, Premium, Diesel),
      parse_number))

# source for `across()`: https://dplyr.tidyverse.org/reference/across.html
# Average available daily prices into monthly nominal gas prices.
# The source begins November 16, 2024; March and May 2026 each miss three days.
# We average the reported days rather than inventing prices for missing dates.

gas_price_averages <- gas_cleaned |>
  mutate(
    month = floor_date(
      Date,
      unit = "month")) |>
  group_by(month, State) |>
  summarise(
    MNA_Regular = mean(Regular, na.rm = TRUE),
    MNA_Mid.Grade = mean(Mid.Grade, na.rm = TRUE),
    MNA_Premium = mean(Premium, na.rm = TRUE),
    MNA_Diesel = mean(Diesel, na.rm = TRUE),
    .groups = "drop")

# Mutating the CPI date variable to be compatible with the date variable
# in the gas price dataframe

CPI_cleaned <- CPI |>
  select(observation_date, CPIAUCNS) |>
  mutate(Date = as.Date(observation_date))

# Reuse the September 2026 CPI base value established above.
# Join CPI to monthly gas prices
gas_cpi <- gas_price_averages |>
  left_join(CPI_cleaned, by = c("month" = "Date"))

# Calculate inflation-adjusted prices
gas_real <- gas_cpi |>
  mutate(
    MRA_Regular = MNA_Regular * (CPI_base / CPIAUCNS),
    MRA_Mid.Grade = MNA_Mid.Grade * (CPI_base / CPIAUCNS),
    MRA_Premium = MNA_Premium * (CPI_base / CPIAUCNS),
    MRA_Diesel = MNA_Diesel * (CPI_base / CPIAUCNS))

# October 2025 CPI is absent from the source, and October 2026 CPI is not
# present in the snapshot. Drop those months; do not impute real prices.
gas_real_complete <- gas_real |>
  filter(!is.na(CPIAUCNS))

# Save the cleaned dataset so it can be imported without re-wrangling.
write_csv(gas_real_complete, file.path(data_dir, "gas_real.csv"))


# Unemployment and labor-force participation — Tetsuya Tanaka


# Create an empty dataframe
unemployment_all <- tibble()

# Loop through all 50 states
for (i in seq_along(state_initials)) {
  # Identify the state
  name <- state_initials[i]
  # Import the state's unemployment data
  new_data <- read_csv(
    file.path(raw_dir, "unemployment", paste0(name, ".csv")),
    show_col_types = FALSE) |>
    #renaming the columns for date and unemployment rate.   
    rename(Date = 1, unemployment_rate = 2) |>
    mutate(State = name)
  
# Add the state's data to the combined dataframe
  unemployment_all <- bind_rows(
    unemployment_all,
    new_data)
}

# Create Year and Month columns to standardize the format
unemployment_all <- unemployment_all |>
  mutate(
    Date = as.Date(Date),
    Year = year(Date),
    Month = month(Date))

# The source has NA unemployment rates for October 2025 in all 50 states.
# Exclude only missing observations; the original raw files remain intact.
unemployment_complete <- unemployment_all |>
  filter(!is.na(unemployment_rate))

# Save the cleaned intermediate data for reproduction and possible later use.
write_csv(unemployment_complete,
          file.path(data_dir, "unemployment_all.csv"))


# Create an empty dataframe
labor_force_all <- tibble()

# Loop through all 50 states
for (i in seq_along(state_initials)) {
  # Identify the state
  name <- state_initials[i]
  # Import the state's labor force participation
  new_data <- read_csv(
    file.path(raw_dir, "labor_force_participation", paste0(name, ".csv")),
    show_col_types = FALSE) |>
    #renaming the columns for date and labor force participation
    rename(Date = 1,
      labor_force_participation_rate = 2) |>
    mutate(State = name)
  # Add the state's data to the combined dataframe
  labor_force_all <- bind_rows(
    labor_force_all,
    new_data)
}

# Create Year and Month columns
labor_force_all <- labor_force_all |>
  mutate(
    Date = as.Date(Date),
    Year = year(Date),
    Month = month(Date)) |>
  select(-Date)

# October 2025 labor-force values are NA for every state in the raw files.
# Drop them rather than substituting invented values.
labor_force_all <- labor_force_all |>
  filter(!is.na(labor_force_participation_rate))

# Save the cleaned dataset so it can be imported without re-wrangling.
write_csv(labor_force_all,
          file.path(data_dir, "labor_force_participation_all.csv"))


# Combine the four main datasets — Tetsuya Tanaka


# Labor-force participation remains available as a separate clean CSV rather than being added to the main analysis table.

# Use the objects created in the sections above; no intermediate rereading.
unemployment <- unemployment_complete
gas <- gas_real_complete
weekly_earning <- weekly_earnings_all
weekly_hours <- weekly_hours_all


gas <- gas |>
  mutate(
    Year = year(month),
    Month = month(month))

# Gas data uses full state names; the labor datasets use two-letter codes.
# Convert gas names to codes and exclude DC, which has no labor-data match.
gas <- gas |>
  mutate(State = state.abb[match(State, state.name)]) |>
  filter(!is.na(State))

# Each state should have at most one observation for each month.
unemployment |> count(State, Year, Month) |> filter(n > 1)
gas |> count(State, Year, Month) |> filter(n > 1)
weekly_earning |> count(State, Year, Month) |> filter(n > 1)
weekly_hours |> count(State, Year, Month) |> filter(n > 1)
# These checks should return zero rows.

# Combine all four datasets
combined_data <- gas |>
  left_join(
    unemployment,
    by = c("State", "Year", "Month")
  ) |>
  left_join(
    weekly_earning,
    by = c("State", "Year", "Month")
  ) |>
  left_join(
    weekly_hours,
    by = c("State", "Year", "Month")
  )

# Keep the monthly date for plotting; remove duplicate source date columns.
combined_data <- combined_data |>
  select(-observation_date, -Date)

# Check the final table for missing data and duplicate state-months.
combined_data |> summarise(across(everything(), ~ sum(is.na(.x))))
combined_data |> count(State, Year, Month) |> filter(n > 1)

# Save the cleaned dataset so it can be imported without re-wrangling.
write_csv(combined_data, file.path(data_dir, "combined_data.csv"))
