library(tidyverse)
library(mdsr)
library(tidyverse)
library(knitr)
library(lubridate)
library(hms)
library(dplyr)


# Import Massachusetts unemployment data

MA <- read_csv("../raw_data/unemployment/MA.csv")

# View the first six observations
head(MA)


# Create a list of all 50 state abbreviations
state_initials <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

# Create an empty dataframe
unemployment_all <- data.frame()

# Loop through all 50 states
for (i in 1:length(state_initials)) {
  
  # Identify the state
  name <- state_initials[i]
  
  # Import the state's unemployment data
  new_data <- read_csv(
    paste0("../raw_data/unemployment/", name, ".csv"),
    show_col_types = FALSE
  ) |>
    #renaming the columns for date and unemployment rate.   
    rename(Date = 1,unemployment_rate = 2) |>
    mutate(State = name)
  
  # Add the state's data to the combined dataframe
  unemployment_all <- bind_rows(
    unemployment_all,
    new_data
  )
}



# Create Year and Month columns to standardize the format
unemployment_all <- unemployment_all |>
  mutate(
    Date = as.Date(Date),
    Year = year(Date),
    Month = month(Date)
  )


# Check for missing unemployment observations
# October 2025 is missing for all 50 states
unemployment_all |>
  filter(is.na(unemployment_rate)) |>
  select(State, Date, unemployment_rate)


#filter out the NA 
unemployment_complete <- unemployment_all |>
  filter(!is.na(unemployment_rate))



write_csv(
  unemployment_complete,
  "../data/unemployment_all.csv"
)

