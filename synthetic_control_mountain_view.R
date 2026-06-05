# ================
# Packages
# ================
install.packages(c("Synth", "tidyverse", "tidycensus"))
library(Synth)
library(tidyverse)
library(tidycensus)

# ================
# Set API Key
# ================
census_api_key("9f250e7095ab636d37cf5b2d204032f9174693fe", install = TRUE, overwrite = TRUE)
readRenviron("~/.Renviron")

# ================
# Get ACS Data
# ================
vars <- c(
  income = "B19013_001",
  rent = "B25064_001",
  renters = "B25003_003",
  total_units = "B25001_001"
)

cities <- c("Mountain View", "Sunnyvale", "Santa Clara", "Fremont",
            "San Mateo", "Milpitas", "Campbell", "Pleasanton", "Dublin")

years <- 2010:2022

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

# ================
# Clean Data
# ================
library(tidyverse)
library(stringr)

city_data_clean <- city_data %>%
  mutate(
    pct_renters = rentersE / total_unitsE,
    income = incomeE,
    median_rent = rentE,
    city = str_remove(NAME, " city, California")
  ) %>%
  select(city, year, income, median_rent, pct_renters) %>%
  arrange(city, year) %>%
  mutate(city_id = as.numeric(factor(city))) %>%  # Must be numeric
  select(city_id, everything())

sapply(city_data_clean, class)

# ================
# Prepare Data for Synth
# ================
treated_id <- city_data_clean %>% filter(city == "Mountain View") %>% distinct(city_id) %>% pull()
control_ids <- city_data_clean %>% filter(city != "Mountain View") %>% distinct(city_id) %>% pull()

dataprep.out <- dataprep(
  foo = city_data_clean,
  predictors = c("income", "pct_renters"),
  special.predictors = list(
    list("median_rent", 2012, "mean"),
    list("median_rent", 2014, "mean"),
    list("median_rent", 2016, "mean")
  ),
  dependent = "median_rent",
  unit.variable = "city_id",   # This MUST be numeric!
  time.variable = "year",
  treatment.identifier = city_data_clean %>% filter(city == "Mountain View") %>% distinct(city_id) %>% pull(),
  controls.identifier = city_data_clean %>% filter(city != "Mountain View") %>% distinct(city_id) %>% pull(),
  time.optimize.ssr = 2010:2016,
  time.plot = 2010:2022
)

 

# ================
# Run Synth
# ================
synth.out <- synth(dataprep.out)

# ================
# Plot Results
# ================
path.plot(
  synth.res = synth.out,
  dataprep.res = dataprep.out,
  Ylab = "Median Rent",
  Xlab = "Year",
  Main = "Rent Control in Mountain View vs Synthetic Control",
  Legend = c("Mountain View", "Synthetic MV")
)

gaps.plot(
  synth.res = synth.out,
  dataprep.res = dataprep.out,
  Ylab = "Effect of Rent Control (Gap)",
  Xlab = "Year",
  Main = "Estimated Treatment Effect of Rent Control"
)

# ================
# See Donor Weights
# ================
synth.tab(dataprep.out, synth.out)$tab.w


