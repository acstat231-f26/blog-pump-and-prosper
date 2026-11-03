library(tidyverse)
library(mdsr)
library(tidyverse)
library(knitr)
library(lubridate)
library(hms)
library(dplyr)



#read all the csv files
unemployment <- read_csv(
  "data/unemployment_all.csv"
)

gas <- read_csv(
  "data/gas_real.csv"
)


weekly_earning <- read_csv("data/weekly_earnings_all.csv")


weekly_hours <- read_csv("data/weekly_hours_all.csv")


gas <- gas |>
  mutate(
    Year = year(month),
    Month = month(month)
  )

#used different identifier for the states
unique(gas$State)
unique(unemployment$State)
unique(weekly_earning$State)

#standardized the state identifier
gas <- gas |>
  mutate(State = state.abb[match(State, state.name)]) |>
  filter(!is.na(State)) #need to remove DC since only gas has DC identified alone 



# Check duplicates in each dataset

unemployment |> count(State, Year, Month) |> filter(n > 1)

gas |> count(State, Year, Month) |> filter(n > 1)

weekly_earning |> count(State, Year, Month) |> filter(n > 1)

weekly_hours |> count(State, Year, Month) |> filter(n > 1)



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

#after checking combined data realized multiple dates so deciding only 1 of it
combined_data <- combined_data |>
  select(-month, -observation_date, -Date)

#final quality check
colSums(is.na(combined_data))




#export
write_csv(combined_data, "data/combined_data.csv")
