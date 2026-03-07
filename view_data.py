import pandas as pd
from tabulate import tabulate

def inspect_strava_data(csv_file):
    # Load the data
    df = pd.read_csv(csv_file)
    
    if df.empty:
        print("The CSV is empty! Check your API scopes.")
        return

    # 1. CLEANING & CONVERSIONS
    # Convert meters to km
    df['dist_km'] = df['distance_m'] / 1000
    
    # Convert time to minutes
    df['duration_min'] = df['time_sec'] / 60
    
    # Calculate Pace (min/km)
    # Note: 5.5 min/km is 5:30 pace
    df['pace_min_km'] = df['duration_min'] / df['dist_km']
    
    # Format the date for readability
    df['date'] = pd.to_datetime(df['date']).dt.strftime('%Y-%m-%d %H:%M')

    # 2. SELECT RELEVANT COLUMNS FOR DISPLAY
    display_cols = [
        'date', 'dist_km', 'duration_min', 'pace_min_km', 
        'avg_heartrate', 'elevation_gain'
    ]
    
    # 3. PRINT RECENT RUNS TABLE
    print("\n--- RECENT RUNNING ACTIVITIES ---")
    print(tabulate(df[display_cols].head(10), headers='keys', tablefmt='psql', floatfmt=".2f"))

    # 4. BAYESIAN SUMMARY (For your Likelihood/Priors)
    print("\n--- STATISTICAL SUMMARY (FOR STAT 405) ---")
    summary = df[['dist_km', 'pace_min_km', 'avg_heartrate']].describe()
    print(tabulate(summary, headers='keys', tablefmt='fancy_grid', floatfmt=".2f"))

    # Check for missing values (crucial for Bayesian modeling)
    missing = df.isnull().sum()
    if missing.any():
        print("\n[!] WARNING: Missing data detected:")
        print(missing[missing > 0])

# Run the inspector
inspect_strava_data('my_strava_data.csv')