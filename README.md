# Strava Bayesian Analysis

This repository collects running activity data from Strava, cleans it into weekly features, and fits Bayesian models to the resulting dataset.

## Repository structure

- `1_data_collection.py` — collects Strava running activities into a raw CSV
- `2_data_cleaning.py` — converts raw activity-level data into weekly features
- `3_exploratory_analysis.R` — exploratory plots and summary analysis
- `4_naive_model.R` — first Bayesian baseline / naive model
- `data/` — raw and cleaned datasets used by the analysis
- `simPPLe/` — helper code used by the naive model

## Prerequisites

- Python 3.8+ (use your virtualenv of choice)
- Install required packages:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install requests pandas
```

## Quick start: run the unified collector

The recommended way to collect your Strava runs now is the unified script `1_data_collection.py`.

It will read `STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`, and `STRAVA_REFRESH_TOKEN` from the environment if present. Otherwise it will prompt you interactively and can walk you through obtaining a refresh token via the OAuth flow.

Run the script:

```bash
# interactive, uses default output filename my_strava_data.csv
python3 1_data_collection.py

# or specify a different output filename
python3 1_data_collection.py -o my_runs.csv
```

What it does:

- Prompts (or reads from env) for your Strava client id/secret
- Optionally runs the OAuth flow to get a refresh token
- Exchanges the refresh token for an access token
- Pages through your activities and keeps only runs
- Writes the output CSV (default `my_strava_data.csv` or the name you pass with `-o`)

## Clean the raw data into weekly features

After collecting your runs, use `2_data_cleaning.py` to convert the raw activity-level CSV into a weekly dataset for downstream Bayesian analysis.

Run the cleaner:

```bash
# explicit input/output paths
.venv/bin/python 2_data_cleaning.py --input data/raw-data.csv --output data/weekly-cleaned-data.csv

# short flags also work
.venv/bin/python 2_data_cleaning.py -i data/raw-data.csv -o data/weekly-cleaned-data.csv
```

What it does:

- Reads the raw running dataset from the input CSV
- Creates a `week` column starting at `1` from the earliest recorded run
- Aggregates runs into weekly rows
- Keeps `weekly_mileage`
- Keeps `weekly_elevation_gain`
- Computes weighted `weekly_avg_pace_min_km` using total weekly time divided by total weekly distance
- Drops heartrate fields from the cleaned output
- Writes the cleaned weekly CSV to the output path

Security note: Do NOT commit your client secret or refresh token to a public repository. `1_data_collection.py` offers to save a local `.env` file; if you use that, add `.env` to `.gitignore`.

## Security / Git hygiene

- Add any files that store secrets to your `.gitignore`. For example, if you create a `.env` file to hold credentials, add `.env` to `.gitignore`.
- Audit your repo history before pushing to a public remote. If credentials were accidentally committed, rotate them immediately (revoke the client secret or refresh token in your Strava settings).

## Notes

- The CSV produced contains columns like `date`, `distance_km`, `time_sec`, `pace_min_km`, `avg_heartrate`, `max_heartrate`, and others useful for analysis.
- The cleaned weekly CSV contains `week`, `weekly_mileage`, `weekly_elevation_gain`, and `weekly_avg_pace_min_km`.
- Consider creating a minimal test run (a few activities) before attempting to download your entire history.
