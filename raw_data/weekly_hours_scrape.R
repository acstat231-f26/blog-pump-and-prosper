
# Scrape monthly average weekly hours for all 50 states
# Source: BLS data published through FRED

library(tidyverse)

# All 50 state abbreviations (built into R)
states <- state.abb

# State FIPS codes in the same order as state.abb
fips <- c(
  1, 2, 4, 5, 6, 8, 9, 10, 12, 13,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
  35, 36, 37, 38, 39, 40, 41, 42, 44, 45,
  46, 47, 48, 49, 50, 51, 53, 54, 55, 56
)

# Specify output folder
output_folder <- "weekly_hours"

# Set number of states
n_iter <- length(states)

for (i in 1:n_iter) {
  
  # Identify the state and its FRED series
  state <- states[i]
  state_code <- sprintf("%02d", fips[i])
  series_id <- paste0("SMU", state_code, "000000500000002")
  
  # Construct the download URL
  url <- paste0(
    "https://fred.stlouisfed.org/graph/fredgraph.csv?id=",
    series_id
  )
  
  # Read the online CSV into R
  hours <- read_csv(url, show_col_types = FALSE)
  
  # Save a separate CSV for the state
  write_csv(
    hours,
    paste0(output_folder, "/", state, ".csv")
  )
  
  # Avoid sending requests too rapidly
  Sys.sleep(1)
}
