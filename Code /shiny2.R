library(shiny)
library(ggplot2)
library(caret)
library(tidyverse)
library(kernlab)
library(reshape2)
library(MLmetrics)
library(randomForest)


data <- read_csv("binded_data.csv")
data_1 <- read_csv("binded_data_1.csv")
data_2 <- read_csv("binded_data_2.csv")

# Research Question 1
sampling_data <-binded_data[sample(nrow(binded_data), 1000 , replace = TRUE), ]

listingsvm_df <- data.frame(bldg_id = sampling_data$bldg_id,
                            energy_usage = sampling_data$combined_usage, 
                            temperature = sampling_data$`Dry Bulb Temperature [°C]`,
                            humidity = sampling_data$`Relative Humidity [%]`,
                            wind = sampling_data$`Wind Speed [m/s]`,
                            time = sampling_data$time
)

listingsvm_df$raised_temperature <- listingsvm_df$temperature + 5

trainList <- createDataPartition(listingsvm_df$energy_usage,p=.80,list=FALSE) # partitioning dataset 
trainSet <- listingsvm_df[trainList,] # 70% trainset
testSet <- listingsvm_df[-trainList,]


fit <- ksvm(energy_usage ~ raised_temperature, data = trainSet, C = 5, cross = 3, prob.model = TRUE)
fit


svm_perd <- predict(fit, testSet)
svm_perd 


temperature <- listingsvm_df$temperature
raised_temperature <- listingsvm_df$raised_temperature
energy_usage <- listingsvm_df$energy_usage
predicted_increased <- svm_perd
time <- listingsvm_df$time
change <- listingsvm_df$change_in_usage



# Combine the variables into a matrix for matplot
y_values <- cbind(temperature, raised_temperature,energy_usage,predicted_increased)

# Research Question 2
sampling_data_1 <-data_1[sample(nrow(data_1), 8000 , replace = TRUE), ]


# Only the columns are taken which could have impact on change in energy with 
# respect to this research question.
listingsvm_df_1 <- data.frame(bldg_id = sampling_data_1$bldg_id,
                              Time = sampling_data_1$time,
                              sqFt = sampling_data_1$in.sqft,
                              energy_usage = sampling_data_1$combined_usage,
                              year_built = sampling_data_1$in.vintage)

# removing patterns and converting it to numeric datatype.
listingsvm_df_1$year_built <- as.numeric(gsub("<", "", gsub("s", "", listingsvm_df_1$year_built)))


# Creating age_group column where houses which are older than 50 years are 
# consider as old and rest are consider as new. Here the age_group is created by
# subtracting present year with the year the house was build.
listingsvm_df_1 <- listingsvm_df_1 %>%
  mutate(vintage = 2024 - year_built,                     # Current year 2024
         age_group = ifelse(vintage > 50, "old", "new"))


listingsvm_df_1$age_group <- as.factor(listingsvm_df_1$age_group) # Ensure age_group is a factor
listingsvm_df_1 <- listingsvm_df_1 %>% ungroup() # Remove grouping for model compatibility


# Partition the dataset into training and testing sets
set.seed(123) # For reproducibility
trainList_1 <- createDataPartition(listingsvm_df_1$energy_usage, p = 0.7, list = FALSE)
trainSet_1 <- listingsvm_df_1[trainList_1, ] # 80% train set
testSet_1 <- listingsvm_df_1[-trainList_1, ] # 20% test set

# Implementing rabdom forest model on train set.
fit_rf <- randomForest(
  energy_usage ~ sqFt + vintage + age_group,  # Formula for predictors
  data = trainSet_1,                          # Training dataset
  ntree = 500,                               # Number of trees
  mtry = 2,                                   # Number of predictors to consider at each split
  importance = TRUE,                          # To compute variable importance
  na.action = na.omit                         # Handle missing values
)

# Print the Random Forest model
print(fit_rf)

# Variable importance
importance(fit_rf)

# Predict energy usage of test set based on the model which was created.
rf_pred <- predict(fit_rf, newdata = testSet_1)

# Research Question 3
sampling_data_2 <- data_2[sample(nrow(data_2), 8000, replace = TRUE), ]

# Only the columns are taken which could have impact on change in energy with 
# respect to this research question.
listingsvm_df_2 <- data.frame(
  bldg_id = sampling_data_2$bldg_id,
  Time = sampling_data_2$time,
  humidity = sampling_data_2$`Relative Humidity [%]`,
  wind = sampling_data_2$`Wind Speed [m/s]`,
  temperature = sampling_data_2$`Dry Bulb Temperature [°C]`,
  energy_usage = sampling_data_2$combined_usage,
  region = sampling_data_2$region,
  fan_energy = sampling_data_2$out.electricity.ceiling_fan.energy_consumption,
  cooling_system_energy = sampling_data_2$out.electricity.cooling.energy_consumption
)

# Increasing energy usage of fan by adding average energy usage of fan energy to initial values
listingsvm_df_2$raised_fan_usage <- listingsvm_df_2$fan_energy + mean(listingsvm_df_2$fan_energy)

# creating data partiton into dataset
trainList_2 <- createDataPartition(listingsvm_df_2$energy_usage, p = 0.8, list = FALSE)
trainSet_2 <- listingsvm_df_2[trainList_2, ] # 80% train set
testSet_2 <- listingsvm_df_2[-trainList_2, ] # 20% test set.


# Implementing random forest model on train set.
rf_model_2 <- randomForest(energy_usage ~ fan_energy + cooling_system_energy + raised_fan_usage,
                           data = trainSet_2,   # Training dataset
                           ntree = 500,         # Number of trees in the forest
                           mtry = 2,            # Number of variables to consider at each split
                           importance = TRUE)   # Enable feature importance

# Print results of the Random Forest model
print(rf_model_2)

# Predicting energy usage of of test set based on model which was created.
rf_predictions_2 <- predict(rf_model_2, newdata = testSet_2)


# Add predictions to the test set
testSet_2$predicted_energy_usage <- rf_predictions_2

# Converting data to long format for ggplot.
library(tidyr)
boxplot_data <- testSet_2 %>%
  select(energy_usage, predicted_energy_usage) %>%
  pivot_longer(cols = c(energy_usage, predicted_energy_usage),
               names_to = "Category",
               values_to = "Values")


# UI
ui <- fluidPage(
  titlePanel("Energy Consumption Analysis"),
  sidebarLayout(
    sidebarPanel(
      helpText("
As eSC, we are leveraging data visualization techniques to better understand energy consumption 
patterns and identify opportunities for reducing electricity usage. By creating various plots, 
we aim to visualize trends in energy usage during the summer months, particularly in July, when demand peaks. 
These visualizations will help us identify key factors that drive high energy usage, such as temperature fluctuations and cooling system usage. Our goal is to pinpoint areas where we can encourage customers to save energy, ultimately reducing the strain on our electrical grid and helping to mitigate the environmental impact of excessive energy consumption. 
These insights will guide our efforts to ensure grid reliability while promoting sustainability."),
      
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Energy vs Dry Bulb", plotOutput("LinePlot3")),
        tabPanel("Predicted Energy vs Dry Bulb + 5", plotOutput("LinePlot4")),
        tabPanel("Temperature vs Energy Trends", plotOutput("LinePlot")),
        tabPanel("BoxPlot", plotOutput("BoxPlot")),
        tabPanel("Energy of Fan vs Cooling", plotOutput("FanCool")),
        tabPanel("Box Plot of Fan & Cool", plotOutput("BoxCool")),
        tabPanel("Percentage Change in Energy after 5 degree",textOutput("totalconsumption")),
      )
      
    )
  )
)

# Server
server <- function(input, output) {
  
  output$LinePlot <- renderPlot({
    # Combine the variables into a matrix for matplot
    y_values <- cbind(temperature, raised_temperature,energy_usage,predicted_increased)
    
    # Create the plot
    matplot(y_values, type = "l", lty = 1, col = c("blue", "red", "green","purple"),
            main = "Temperature and Energy Usage Trends",
            xlab = "Observation Index", ylab = "Values")
    
    # Add a legend
    legend("bottomright", legend = c("Temperature", "Raised Temperature", "Energy Usage", "Predicted Increased"),
    col = c("blue", "red", "green", "purple"), lty = 1)
  })
  
  output$LinePlot3 <- renderPlot({
    # Create the plot
    matplot(y_values, type = "l", lty = 1, col = c("blue", "red", "green","purple"),
            main = "Temperature and Energy Usage Trends",
            xlab = "Observation Index", ylab = "Values")
    
    # Add a legend
    legend("bottomright", legend = c("Temperature", "Raised Temperature", "Energy Usage", "Predicted Increased"),
           col = c("blue", "red", "green", "purple"), lty = 1)
    
    y_values <- cbind(energy_usage, predicted_increased)
    
    
    # Create the plot
    matplot(y_values, type = "l", lty = 1, col = c("blue", "red"),
            main = "Energy Usage Trends",
            xlab = "Temperature & Energy", ylab = "Values")
    
  })
  
  output$LinePlot4 <- renderPlot({
    ggplot(testSet, aes(x = raised_temperature, y = predicted_increased)) +
      geom_point(color = "blue", size = 3) +  # Scatter points
      geom_smooth(method = "lm", color = "red", se = FALSE, size = 1,formula = 'y ~ x') +  # Linear regression line
      labs(
        title = "Predicted Energy Usage vs. Increased Temperature",
        x = "Raised Temperature (°C)",
        y = "Predicted Energy Usage"
      ) +
      theme_minimal(base_size = 14)
    
  })
  
  output$BoxPlot <- renderPlot({
    ggplot(testSet_1, aes(x = factor(sqFt), y = energy_usage, color = age_group)) +
      geom_boxplot() +
      labs(
        title = "Energy Usage Comparison Between Old and New Houses by sqFt",
        x = "Square Footage (sqFt)",
        y = "Energy Usage",
        color = "House Age Group"
      ) +
      theme_minimal() 
  })
  
  
  output$FanCool <- renderPlot({
    # Load necessary libraries
    library(ggplot2)
    library(reshape2)
    library(lubridate)
    
    # Reshape data
    long_data_1 <- melt(
      testSet_2,
      id.vars = "Time",
      measure.vars = c("fan_energy", "cooling_system_energy"),
      variable.name = "Energy_Type",
      value.name = "Energy_Usage"
    )
    
    # Ensure Time contains only hours (adjust if Time is datetime)
    long_data_1$Hour <- format(as.POSIXct(long_data_1$Time, format = "%Y-%m-%d %H:%M:%S"), "%H")
    
    # Plot bar chart
    ggplot(long_data_1, aes(x = Hour, y = Energy_Usage, fill = Energy_Type)) +
      geom_bar(stat = "identity", position = "dodge", width = 0.8) +  # Increase bar width
      labs(
        title = "Energy Usage Over Time (Hourly)",
        x = "Hour",
        y = "Energy Usage",
        fill = "Energy Type"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),  # Rotate x-axis labels
        legend.position = "top"
      )
  })
  
  
  
  output$BoxCool <- renderPlot({
    
    ggplot(boxplot_data, aes(x = Category, y = Values, fill = Category)) +
      geom_boxplot(outlier.colour = "red", outlier.size = 2) + # Highlight outliers
      scale_y_continuous(breaks = seq(-4, 10, by = 2)) +  
      labs(
        title = "Boxplot of Energy Usage and Predicted Usage",
        x = "Category",
        y = "Values"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        legend.position = "none",  # Remove legend since Category labels are sufficient
        plot.title = element_text(hjust = 0.5)  # Center the title
      )
  })
  
  output$totalconsumption <- renderText({
    # Calculate the total initial consumption for the entire data
    total_initial_consumption <- sum(testSet$energy_usage, na.rm = TRUE)
    total_changed_consumption <- sum(svm_perd, na.rm = TRUE)
    change_consumption <- (sum(total_initial_consumption)- sum(total_changed_consumption))/(sum(total_initial_consumption))*100
    paste("The percentage change in energy is", change_consumption, "%")
  })
  
  
}

# Run App
shinyApp(ui = ui, server = server)
