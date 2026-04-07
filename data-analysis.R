library(dplyr)
library(ggplot2)
ellie <- read.csv("data/ellie.csv") %>%
  select("date", "elevation_gain", "distance_km", "pace_min_km")
# Select runs from 2025/26
ellie <- ellie %>%
  mutate(date = as.Date(ellie$date)) %>%
  filter(date > as.Date("2024-01-01"))
View(ellie)
# Distance vs pace
ggplot() +
  geom_point(data = ellie, aes(x = distance_km, y = pace_min_km)) +
  labs(x = "Distance (km)", y = "Pace (min/km)") +
  theme_minimal()
# Elevation gain vs pace
ggplot() +
  geom_point(data = ellie, aes(x = elevation_gain, y = pace_min_km)) +
  labs(x = "Elevation gain (m)", y = "Pace (min/km)") +
  theme_minimal()
# Date vs pace
ggplot() +
  geom_point(data = ellie, aes(x = date, y = pace_min_km)) +
  labs(x = "Date", y = "Pace (min/km)") +
  theme_minimal()
# Date vs distance
ggplot() +
  geom_point(data = ellie, aes(x = date, y = distance_km)) +
  labs(x = "Date", y = "Distance (km)") +
  theme_minimal()
cumsum(weekdays(ellie$date) == "Friday")
ggplot() +
  geom_histogram(data = ellie, aes(x = ))
