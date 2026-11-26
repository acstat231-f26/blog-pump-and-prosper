# Prepare comparisons of real regular gasoline prices across all
# chronological pairs of months for each state.
#
# Author: Declan DuBois
# Input: combined_data.csv
# Output: gas_price_comparisons.csv

library(tidyverse)

# Import the relevant variables from the master dataset.
gas <- read_csv(
  "../data/combined_data.csv",
  show_col_types = FALSE
) |>
  select(State, Region, month, MRA_Regular)

# Create a lookup table to replace state abbreviations with full names.
state_lookup <- tibble(
  State = state.abb,
  state_name = state.name
)

gas <- gas |>
  left_join(state_lookup, by = "State") |>
  select(
    State = state_name,
    Region,
    month,
    MRA_Regular
  )

# Separate starting and ending observations so that each month
# can be compared with every subsequent month for the same state.
start <- gas |>
  rename(
    start_month = month,
    start_price = MRA_Regular
  )

end <- gas |>
  rename(
    end_month = month,
    end_price = MRA_Regular
  )

# Generate all chronological month pairs and calculate the
# proportional change in inflation-adjusted gasoline prices.
comparison <- start |>
  inner_join(
    end,
    by = c("State", "Region"),
    relationship = "many-to-many"
  ) |>
  filter(start_month < end_month) |>
  mutate(
    pct_change = (end_price - start_price) / start_price,
    start_month = format(start_month, "%Y-%m"),
    end_month = format(end_month, "%Y-%m")
  ) |>
  select(
    State, Region, start_month, end_month,
    start_price, end_price, pct_change
  ) |>
  arrange(start_month, end_month, State)

# Check for missing values.
comparison |>
  summarise(across(everything(), ~ sum(is.na(.x))))

# Check for duplicate state-period comparisons.
comparison |>
  count(State, start_month, end_month) |>
  filter(n > 1)

# Export the analysis-ready dataset for use in the blog.
write_csv(
  comparison,
  "../data/gas_price_comparisons.csv"
)