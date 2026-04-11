library(dplyr)
library(ggplot2)

ellie <- read.csv("data/raw-data.csv") %>%
  select("date", "elevation_gain", "distance_km", "pace_min_km") %>%
  filter(pace_min_km < 7)
# Select runs from 2025/26

ellie_2526 <- ellie %>%
  mutate(date = as.Date(ellie$date)) %>%
  filter(date > as.Date("2025-01-01"))

ellie_weekly_2526 <- ellie_2526 %>% 
  mutate(week = cut.Date(date, breaks = "1 week", labels = FALSE)) %>%
  group_by(week) %>%
  summarize(weekly_mileage = sum(distance_km))

View(ellie_weekly_2526)
#View(ellie)

ellie_weekly_6mo <- ellie %>%
  mutate(date = as.Date(ellie$date)) %>%
  filter(date > as.Date("2025-11-01")) %>% 
  mutate(week = cut.Date(date, breaks = "1 week", labels = FALSE)) %>%
  group_by(week) %>%
  summarize(weekly_mileage = sum(distance_km))

# ============ VISUALIZATION ============
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
# Weekly mileage since 2025
ggplot() +
  geom_col(data = ellie_weekly_2526, 
           aes(x = week, y = weekly_mileage))
ggplot() +
  geom_col(data = ellie_weekly_6mo, 
           aes(x = week, y = weekly_mileage))
