library(tidyverse)
library(mdsr)
library(tidyverse)
library(knitr)
library(lubridate)
library(hms)
library(dplyr)


# Create a list of all 50 states
state_initials <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

# Create an empty dataframe
labor_force_all <- data.frame()

# Loop through all 50 states
for (i in 1:length(state_initials)) {
  # Identify the state
  name <- state_initials[i]
  # Import the state's labor force participation
  new_data <- read_csv(
    paste0("raw_data/labor_force_participation/", name, ".csv"),
    show_col_types = FALSE
  ) |>
    #renaming the columns for date and labor force participation
    rename(
      Date = 1,
      labor_force_participation_rate = 2
    ) |>
    mutate(State = name)
  # Add the state's data to the combined dataframe
  labor_force_all <- bind_rows(
    labor_force_all,
    new_data
  )
}

# Create Year and Month columns
labor_force_all <- labor_force_all |>
  mutate(
    Date = as.Date(Date),
    Year = year(Date),
    Month = month(Date)
  ) |>
  select(-Date)

# Check missing values
colSums(is.na(labor_force_all))


# Remove missing observations
labor_force_all <- labor_force_all |>
  filter(!is.na(labor_force_participation_rate))


# Export
write_csv(
  labor_force_all,
  "data/labor_force_participation_all.csv"
)
