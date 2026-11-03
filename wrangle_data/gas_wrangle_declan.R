library(readr)
library(tidyverse)
library(dplyr)
library(lubridate)

# Import

gas_raw <- read.csv("raw_data/MasterGas.csv")
CPI <- read.csv("raw_data/CPIAUCNS.csv")

gas_cleaned <- gas_raw |>
  mutate(
    Date = as.Date(Date),
    across(
      c(Regular, Mid.Grade, Premium, Diesel),
      parse_number
    )
  )

# source for `across()`: https://dplyr.tidyverse.org/reference/across.html

# Wrangling a new dataframe which contains the average monthly price 
# for each gasoline type in nominal terms 

gas_price_averages <- gas_cleaned |>
  mutate(
    month = floor_date(
      Date,
      unit = "month"),
  ) |>
  group_by(month, State) |>
  summarise(
    MNA_Regular = mean(Regular, na.rm = TRUE),
    MNA_Mid.Grade = mean(Mid.Grade, na.rm = TRUE),
    MNA_Premium = mean(Premium, na.rm = TRUE),
    MNA_Diesel = mean(Diesel, na.rm = TRUE)
  )

# Mutating the CPI date variable to be compatible with the date variable
# in the gas price dataframe

CPI_cleaned <- CPI |>
  mutate(
    Date = as.Date(observation_date),
  )

# Extract base-month CPI
CPI_base <- CPI_cleaned |>
  filter(Date == as.Date("2026-09-01")) |>
  pull(CPIAUCNS)

# Join CPI to monthly gas prices
gas_cpi <- gas_price_averages |>
  left_join(CPI_cleaned, by = c("month" = "Date"))

# Calculate inflation-adjusted prices
gas_real <- gas_cpi |>
  mutate(
    MRA_Regular = MNA_Regular * (CPI_base / CPIAUCNS),
    MRA_Mid.Grade = MNA_Mid.Grade * (CPI_base / CPIAUCNS),
    MRA_Premium = MNA_Premium * (CPI_base / CPIAUCNS),
    MRA_Diesel = MNA_Diesel * (CPI_base / CPIAUCNS)
  )

#Exclude Oct 2025 (govt shutdown) and Oct 2026 (not published yet)
gas_real_complete <- gas_real |>
  filter(!is.na(CPIAUCNS))

write_csv(gas_real_complete, "data/gas_real.csv")
  