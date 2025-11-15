# South Carolina Residential Energy Consumption Analysis

A comprehensive data science project analyzing residential energy consumption patterns in South Carolina counties, examining the impact of temperature changes, house age, and ceiling fan usage on energy consumption during July 2023.

## Project Overview

This project investigates three key research questions related to residential energy consumption:

1. **Temperature Impact**: How does a 5°C temperature increase affect household energy usage?
2. **House Age Analysis**: Do older houses (>50 years) consume more energy than newer houses with similar square footage?
3. **Ceiling Fan Efficiency**: What is the impact of increased ceiling fan usage on overall energy consumption?

## Technologies Used

- **Language**: R (R Markdown)
- **Key Libraries**:
  - `tidyverse` - Data manipulation and visualization
  - `dplyr` - Data transformation
  - `arrow` - Reading Parquet files
  - `caret` - Machine learning workflows
  - `randomForest` - Random Forest modeling
  - `kernlab` - Support Vector Machine (KSVM)
  - `ggplot2` - Advanced visualizations
  - `xgboost` - Gradient boosting (imported but not actively used)

## Data Sources

The project uses three main data sources from AWS S3:

1. **Static House Information**: Building characteristics and metadata
2. **Weather Data**: Hourly weather observations by county (2023)
3. **Energy Consumption Data**: Hourly energy usage per household (2023)

All data is filtered to focus on July 2023 for consistency.

## Features

### Data Processing
- Automated data fetching from multiple counties
- Merging weather, housing, and energy datasets
- Missing value handling and data cleaning
- Feature engineering (combined energy usage, temperature adjustments, age groups)

### Machine Learning Models
- **Support Vector Machine (KSVM)**: Temperature-energy relationship prediction
- **Random Forest**: Multi-factor energy consumption modeling
- Model evaluation using MAE and R-squared metrics

### Visualizations
- Time series plots of temperature and energy trends
- Boxplots comparing energy usage across different house categories
- Actual vs. predicted energy consumption comparisons

## Installation

### Prerequisites
- R (version 4.0 or higher recommended)
- RStudio (optional but recommended)

### Required R Packages

```r
install.packages(c(
  "arrow",
  "tidyverse",
  "dplyr",
  "readr",
  "caret",
  "kernlab",
  "MLmetrics",
  "randomForest",
  "xgboost",
  "ggplot2",
  "tidyr"
))
```

## Usage

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd <your-repo-name>
   ```

2. **Open the R Markdown file**:
   ```r
   # In RStudio
   # File > Open File > ids project new.Rmd
   ```

3. **Run the analysis**:
   - Execute chunks sequentially in RStudio, or
   - Knit the entire document: `Ctrl + Shift + K` (Windows) or `Cmd + Shift + K` (Mac)

4. **Output files**:
   - `binded_data.csv` - Merged dataset for Research Question 1
   - `binded_data_1.csv` - Merged dataset for Research Question 2
   - Generated plots and model results

## Project Structure

### Research Question 1: Temperature Impact Analysis
- **Counties**: G4500910, G4500810, G4500450, G4500190, G4500070
- **Sample Size**: 800 houses (random sampling)
- **Model**: KSVM with C=5, 3-fold cross-validation
- **Key Finding**: Predicts energy usage changes with 5°C temperature increase

### Research Question 2: House Age vs. Energy Consumption
- **Counties**: G4500830, G4500510, G4500790, G4500150, G4500730
- **Sample Size**: 200 houses
- **Model**: Random Forest (500 trees, mtry=2)
- **Features**: Square footage, vintage, age group classification

### Research Question 3: Ceiling Fan Impact
- **Counties**: 11 counties (G4500750, G4500670, etc.)
- **Sample Size**: 600 houses
- **Model**: Random Forest analyzing fan energy vs. cooling system energy
- **Key Analysis**: Impact of increased fan usage on total energy consumption

## Model Performance

Each research question includes evaluation metrics:
- **Mean Absolute Error (MAE)**: Average prediction error
- **R-squared**: Model fit quality (Questions 2 & 3)
- **Variable Importance**: Feature significance rankings

## Data Sampling Strategy

- Random sampling with replacement from county subsets
- Stratified by county to ensure geographic representation
- Sample sizes vary by research question complexity (200-8000 observations)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## Notes

- Data is accessed directly from AWS S3 buckets - no local data storage required
- Processing time varies based on sample size (larger samples may take 10-30 minutes)
- Internet connection required for data fetching
- Some county codes may have limited data availability

## License

[Add your license here - e.g., MIT, GPL, etc.]

## Contact

[Add your contact information or link to your profile]

## Acknowledgments

- Data source: Introduction to Data Science course materials (AWS S3)
- South Carolina energy consumption dataset (2023)
- Weather data from various SC counties

---

**Last Updated**: November 2024
