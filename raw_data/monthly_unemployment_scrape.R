# Scrape monthly unemployment data for all 50 states
# Source: BLS data published through FRED

library(tidyverse)

# All 50 state abbreviations (built into R)
states <- state.abb

# Specify output folder
output_folder <- "unemployment"

# Set number of states
n_iter <- length(states)

for (i in 1:n_iter) {
  
  # Identify the state and its FRED series
  state <- states[i]
  series_id <- paste0(state, "UR")
  
  # Construct the download URL
  url <- paste0(
    "https://fred.stlouisfed.org/graph/fredgraph.csv?id=",
    series_id
  )
  
  # Read the online CSV into R
  unemployment <- read_csv(url, show_col_types = FALSE)
  
  # Save a separate CSV for the state
  write_csv(
    unemployment,
    paste0(output_folder, "/", state, ".csv")
  )
  
  # Avoid sending requests too rapidly
  Sys.sleep(2)
}