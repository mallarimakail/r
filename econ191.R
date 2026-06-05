# Install if not already installed
packages <- c("tidycensus", "tidyverse")
install.packages(setdiff(packages, installed.packages()[,"Package"]))

# Load packages
library(tidycensus)
library(tidyverse)

# Set your Census API key
census_api_key("9f250e7095ab636d37cf5b2d204032f9174693fe", install = TRUE, overwrite = TRUE)
readRenviron("~/.Renviron")

# Define ACS variables to fetch
vars <- c(
  income = "B19013_001",           # Median household income
  rent = "B25064_001",             # Median gross rent
  renters = "B25003_003",          # Renter-occupied units
  owners = "B25003_002",           # Owner-occupied units
  total_units = "B25001_001",      # Total housing units
  population = "B01003_001",       # Total population
  home_value = "B25077_001"        # Median home value
)

# Define cities and years
cities <- c("Mountain View", "Sunnyvale", "Santa Clara", "Fremont", 
            "San Mateo", "Milpitas", "Campbell", "Pleasanton", "Dublin")
years <- 2010:2022

# Get ACS data
city_data <- map_dfr(years, function(yr) {
  get_acs(
    geography = "place",
    variables = vars,
    state = "CA",
    year = yr,
    survey = "acs5",
    output = "wide"
  ) %>%
    filter(NAME %in% paste0(cities, " city, California")) %>%
    mutate(
      year = yr,
      city = str_remove(NAME, " city, California")
    )
})

# Add inflation data (you'll need to replace this with real values or source dynamically)
inflation_df <- tibble(
  year = 2010:2022,
  inflation = c(218.056, 224.939, 229.594, 233.049, 236.736, 237.017, 240.007, 245.120, 251.107, 255.657, 258.811, 270.970, 292.655)
)

# Merge and calculate control variables
city_data_clean <- city_data %>%
  left_join(inflation_df, by = "year") %>%
  mutate(
    pct_renters = rentersE / total_unitsE,
    homeownership_rate = ownersE / total_unitsE,
    wealth_gap_proxy = home_valueE / rentE,
    city_id = as.numeric(factor(city)),
    income = incomeE,
    median_rent = rentE,
    median_home_value = home_valueE,
    log_median_rent = log(median_rent),
    log_median_home_value = log(median_home_value),
    treatment = ifelse(city == "Mountain View", 1, 0),
    post_treatment = ifelse(year >= 2015, 1, 0)
  ) %>%
  select(city_id, city, year, income, median_rent, log_median_rent,
         pct_renters, homeownership_rate, inflation, median_home_value,
         log_median_home_value, wealth_gap_proxy, treatment, post_treatment)

# DiD Model 1: Effect on log home value (wealth accumulation)
model_home_value <- lm(
  log_median_home_value ~ treatment * post_treatment + income + pct_renters + homeownership_rate + inflation + factor(city),
  data = city_data_clean
)

# DiD Model 2: Effect on wealth gap proxy (home value to rent ratio)
model_wealth_gap <- lm(
  wealth_gap_proxy ~ treatment * post_treatment + income + pct_renters + homeownership_rate + inflation + factor(city),
  data = city_data_clean
)



# Output summaries
summary(model_home_value)
summary(model_wealth_gap)


### Graphs

## Median Home Value Over Time by City

library(ggplot2)

ggplot(city_data_clean, aes(x = year, y = median_home_value, color = city)) +
  geom_line(size = 1) +
  geom_vline(xintercept = 2015, linetype = "dashed", color = "red") +
  labs(title = "Median Home Value Over Time by City",
       subtitle = "Dashed line = Rent control policy in Mountain View (2015)",
       x = "Year", y = "Median Home Value ($)") +
  theme_minimal()

## Log Median Home Value: Treatment Vs. Control

avg_values <- city_data_clean %>%
  mutate(group = ifelse(treatment == 1, "Treatment (Mountain View)", "Control Cities")) %>%
  group_by(group, year) %>%
  summarise(avg_log_home_value = mean(log_median_home_value, na.rm = TRUE), .groups = "drop")

ggplot(avg_values, aes(x = year, y = avg_log_home_value, color = group)) +
  geom_line(size = 1.2) +
  geom_vline(xintercept = 2015, linetype = "dashed", color = "red") +
  labs(title = "Log Median Home Value: Treatment vs. Control",
       subtitle = "Mountain View vs. Control Cities",
       x = "Year", y = "Log(Median Home Value)") +
  theme_minimal()

## Owner vs. renter ratio

gap_plot <- city_data_clean %>%
  mutate(group = ifelse(treatment == 1, "Mountain View", "Control Cities")) %>%
  group_by(group, year) %>%
  summarise(avg_gap = mean(wealth_gap_proxy, na.rm = TRUE), .groups = "drop")

ggplot(gap_plot, aes(x = year, y = avg_gap, color = group)) +
  geom_line(size = 1.2) +
  geom_vline(xintercept = 2015, linetype = "dashed", color = "red") +
  labs(title = "Wealth Gap Proxy: Renters vs Owners",
       subtitle = "Effect of Rent Control (Mountain View, 2015)",
       x = "Year", y = "Gap in Wealth (Homeowner - Renter)") +
  theme_minimal()

## Home Values By City Over Time

ggplot(city_data_clean, aes(x = year, y = median_home_value)) +
  geom_line(color = "#2c3e50") +
  facet_wrap(~ city) +
  geom_vline(xintercept = 2015, linetype = "dashed", color = "red") +
  labs(title = "Home Values by City Over Time", x = "Year", y = "Median Home Value") +
  theme_minimal()

## DiD Visualization
did_plot <- city_data_clean %>%
  mutate(group = ifelse(treatment == 1, "Mountain View", "Control Cities")) %>%
  group_by(group, year) %>%
  summarise(mean_home_value = mean(median_home_value, na.rm = TRUE), .groups = "drop")

ggplot(did_plot, aes(x = year, y = mean_home_value, color = group)) +
  geom_line(size = 1.2) +
  geom_point() +
  geom_vline(xintercept = 2015, linetype = "dashed", color = "red") +
  labs(title = "Difference-in-Differences Visualization",
       subtitle = "Parallel Trends Assumption + Policy Effect (Mountain View)",
       x = "Year", y = "Average Median Home Value") +
  theme_minimal()

##
# Load packages
library(dplyr)
library(knitr)
library(kableExtra)

# Create a summary table by city and year
city_year_summary <- city_data_clean %>%
  group_by(city, year) %>%
  summarise(
    median_home_value = mean(median_home_value, na.rm = TRUE),
    median_rent = mean(median_rent, na.rm = TRUE),
    income = mean(income, na.rm = TRUE),
    pct_renters = mean(pct_renters, na.rm = TRUE),
    homeownership_rate = mean(homeownership_rate, na.rm = TRUE),
    wealth_gap_proxy = mean(wealth_gap_proxy, na.rm = TRUE),
    .groups = "drop"
  )

# View the first few rows
head(city_year_summary)

# Optional: display a nicely formatted table for a specific year
city_year_summary %>%
  filter(year == 2015) %>%
  kable("html", caption = "Summary Statistics by City (Year: 2015)") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))

