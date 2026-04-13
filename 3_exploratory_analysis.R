library(dplyr)
library(ggplot2)
library(readr)
library(scales)

weekly <- read_csv("data/weekly_data.csv", show_col_types = FALSE) %>%
  mutate(
    week = as.integer(week),
    week_start = as.Date("2020-03-02") + (week - 1) * 7
  ) %>%
  arrange(week)

if (!all(c("weekly_mileage", "weekly_avg_pace_min_km") %in% names(weekly))) {
  stop("Weekly dataset must contain weekly_mileage and weekly_avg_pace_min_km columns.")
}

if (!"weekly_elevation_gain" %in% names(weekly)) {
  weekly <- weekly %>% mutate(weekly_elevation_gain = NA_real_)
}

dir.create("visualizations", showWarnings = FALSE)

summary_stats <- bind_rows(
  weekly %>%
    summarize(
      variable = "weekly_mileage",
      n = sum(!is.na(weekly_mileage)),
      mean = mean(weekly_mileage, na.rm = TRUE),
      sd = sd(weekly_mileage, na.rm = TRUE),
      min = min(weekly_mileage, na.rm = TRUE),
      q1 = quantile(weekly_mileage, 0.25, na.rm = TRUE),
      median = median(weekly_mileage, na.rm = TRUE),
      q3 = quantile(weekly_mileage, 0.75, na.rm = TRUE),
      max = max(weekly_mileage, na.rm = TRUE)
    ),
  weekly %>%
    summarize(
      variable = "weekly_avg_pace_min_km",
      n = sum(!is.na(weekly_avg_pace_min_km)),
      mean = mean(weekly_avg_pace_min_km, na.rm = TRUE),
      sd = sd(weekly_avg_pace_min_km, na.rm = TRUE),
      min = min(weekly_avg_pace_min_km, na.rm = TRUE),
      q1 = quantile(weekly_avg_pace_min_km, 0.25, na.rm = TRUE),
      median = median(weekly_avg_pace_min_km, na.rm = TRUE),
      q3 = quantile(weekly_avg_pace_min_km, 0.75, na.rm = TRUE),
      max = max(weekly_avg_pace_min_km, na.rm = TRUE)
    ),
  weekly %>%
    summarize(
      variable = "weekly_elevation_gain",
      n = sum(!is.na(weekly_elevation_gain)),
      mean = mean(weekly_elevation_gain, na.rm = TRUE),
      sd = sd(weekly_elevation_gain, na.rm = TRUE),
      min = min(weekly_elevation_gain, na.rm = TRUE),
      q1 = quantile(weekly_elevation_gain, 0.25, na.rm = TRUE),
      median = median(weekly_elevation_gain, na.rm = TRUE),
      q3 = quantile(weekly_elevation_gain, 0.75, na.rm = TRUE),
      max = max(weekly_elevation_gain, na.rm = TRUE)
    )
) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

write_csv(summary_stats, "visualizations/weekly_summary_stats.csv")

base_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

weekly_mileage_plot <- ggplot(weekly, aes(x = week_start, y = weekly_mileage)) +
  geom_col(fill = "#4C78A8", width = 6) +
  geom_smooth(se = FALSE, color = "#1F2A44", linewidth = 0.8, method = "loess", span = 0.2) +
  labs(
    title = "Weekly Mileage Over Time",
    x = "Week",
    y = "Weekly mileage (km)"
  ) +
  scale_y_continuous(labels = label_number(accuracy = 1)) +
  base_theme

weekly_pace_plot <- ggplot(
  weekly %>% filter(!is.na(weekly_avg_pace_min_km), weekly_mileage > 0),
  aes(x = week_start, y = weekly_avg_pace_min_km)
) +
  geom_line(color = "#F58518", linewidth = 0.8) +
  geom_smooth(se = FALSE, color = "#7A3E00", linewidth = 0.8, method = "loess", span = 0.2) +
  labs(
    title = "Weekly Average Pace Over Time",
    x = "Week",
    y = "Weighted average pace (min/km)"
  ) +
  scale_y_continuous(labels = label_number(accuracy = 0.1)) +
  base_theme

weekly_relationship_plot <- ggplot(
  weekly %>% filter(!is.na(weekly_avg_pace_min_km), weekly_mileage > 0),
  aes(
    x = weekly_mileage,
    y = weekly_avg_pace_min_km,
    color = weekly_elevation_gain
  )
) +
  geom_point(alpha = 0.8, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "#222222", linewidth = 0.8) +
  labs(
    title = "Weekly Mileage and Pace Relationship",
    x = "Weekly mileage (km)",
    y = "Weighted average pace (min/km)",
    color = "Weekly\nelevation gain"
  ) +
  scale_color_viridis_c(option = "C", end = 0.9, na.value = "grey70") +
  base_theme

ggsave(
  filename = "visualizations/weekly_mileage_over_time.png",
  plot = weekly_mileage_plot,
  width = 9,
  height = 5,
  dpi = 300
)

ggsave(
  filename = "visualizations/weekly_avg_pace_over_time.png",
  plot = weekly_pace_plot,
  width = 9,
  height = 5,
  dpi = 300
)

ggsave(
  filename = "visualizations/weekly_mileage_vs_pace.png",
  plot = weekly_relationship_plot,
  width = 8,
  height = 5,
  dpi = 300
)

print(weekly_mileage_plot)
print(weekly_pace_plot)
print(weekly_relationship_plot)
print(summary_stats)
