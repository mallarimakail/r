# Rent Control & Housing Inequality in Silicon Valley
### A Difference-in-Differences Analysis — Mountain View, CA (2010–2022)

## Overview

This project investigates whether Mountain View's 2016 rent control policy (Measure V / CSFRA) causally affected housing inequality and homeownership accessibility in the Silicon Valley area. Using a **difference-in-differences (DiD) regression approach**, Mountain View is compared against eight demographically and economically similar California cities that did not implement rent control during the same period.

The analysis finds that while Mountain View saw sharper home value growth after 2015, the DiD estimators were **statistically insignificant** — suggesting rent control did not causally widen the wealth gap between renters and homeowners, nor did it stunt property value appreciation.

---

## Research Questions

1. Did Mountain View's rent control policy affect home value appreciation relative to comparable cities?
2. Did rent control widen the structural accessibility gap between renters and homeowners (measured as the home value-to-rent ratio)?

---

## Methodology

- **Design:** Difference-in-Differences (DiD)
- **Treatment group:** Mountain View (rent control implemented 2015–2016)
- **Control group:** Sunnyvale, Santa Clara, Fremont, San Mateo, Milpitas, Campbell, Pleasanton, Dublin
- **Time period:** 2010–2022
- **Models:**
  - Model 1: Log median home value ~ treatment × post-treatment + controls + city fixed effects
  - Model 2: Home value-to-rent ratio ~ treatment × post-treatment + controls + city fixed effects

---

## Data Sources

| Source | Variables |
|---|---|
| U.S. Census Bureau — American Community Survey (ACS 5-Year) | Median household income, median gross rent, renter/owner-occupied units, total housing units, population, median home value |
| Bureau of Labor Statistics (BLS) | Annual CPI inflation index (San Francisco Bay Area) |

Data was pulled directly via the `tidycensus` R package using the Census API.

---

## Key Variables

| Variable | ACS Code | Description |
|---|---|---|
| Median Household Income | B19013_001 | City-level median income |
| Median Gross Rent | B25064_001 | City-level median rent |
| Renter-Occupied Units | B25003_003 | Count of renter households |
| Owner-Occupied Units | B25003_002 | Count of owner households |
| Total Housing Units | B25001_001 | Total housing stock |
| Median Home Value | B25077_001 | City-level median home value |

**Derived variables:**
- `pct_renters` — renter-occupied / total units
- `homeownership_rate` — owner-occupied / total units
- `wealth_gap_proxy` — median home value / median rent (structural accessibility indicator)
- `log_median_home_value` — log transformation for regression

---

## Requirements

**R version:** 4.0+

**Packages:**
```r
install.packages(c("tidycensus", "tidyverse", "ggplot2", "dplyr", "knitr", "kableExtra"))
```

**Census API Key:**

You will need a free Census API key from [api.census.gov](https://api.census.gov/data/key_signup.html). Replace the key in the script:
```r
census_api_key("YOUR_API_KEY_HERE", install = TRUE, overwrite = TRUE)
```

---

## How to Run

1. Clone this repository
2. Open `econ191.R` in RStudio or any R environment
3. Replace the Census API key with your own (see above)
4. Run the script top to bottom — it will fetch data, clean it, run regressions, and produce all figures

---

## Outputs

**Regression summaries** (printed to console):
- Model 1: DiD effect on log median home value
- Model 2: DiD effect on home value-to-rent ratio

**Figures generated:**
- Median home value over time by city (with policy cutoff line)
- Log median home value: Mountain View vs. control cities
- Wealth gap proxy (home value / rent) over time
- Home values by city — faceted panel chart
- Difference-in-differences visualization (parallel trends + policy effect)

---

## Results Summary

Neither DiD estimator reached statistical significance:
- **Model 1** (log home value): interaction coefficient = 0.010, p = 0.765
- **Model 2** (home value-to-rent ratio): interaction coefficient = 21.00, p = 0.185

This suggests that Mountain View's rent control policy did not causally affect home value appreciation or the renter-to-homeowner accessibility gap relative to control cities. Regional economic forces — particularly rising incomes and Bay Area-wide housing demand — appear to explain most of the variation.

---

## Limitations

- No unit-type breakdown (studio, 1BR, 2BR) available for control cities, limiting granular comparison
- ACS 5-year estimates may smooth over year-to-year variation
- Study period ends at 2022; longer-term effects (e.g., new construction, investor behavior) are not captured

---

## Author

**Kail Mallari**  
University of California, Berkeley — Econ 191 (Spring 2025)
