import requests
import pandas as pd
import time

# --- CONFIGURATION ---
CLIENT_ID = '208904'
CLIENT_SECRET = 'f588e3d157040b1d491e1343a9a0d13b6bbec1d4'
REFRESH_TOKEN = '5c92171c9a13fc340102400291b50fa4407bde92'

def get_access_token():
    """Uses the refresh token to get a valid 6-hour access token."""
    url = "https://www.strava.com/oauth/token"
    payload = {
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'refresh_token': REFRESH_TOKEN,
        'grant_type': 'refresh_token'
    }
    response = requests.post(url, data=payload)
    if response.status_code == 200:
        return response.json()['access_token']
    else:
        print(f"Failed to refresh token: {response.text}")
        return None

def fetch_all_running_data(access_token):
    """Fetches all activities and filters for runs."""
    url = "https://www.strava.com/api/v3/athlete/activities"
    headers = {'Authorization': f'Bearer {access_token}'}
    
    all_runs = []
    page = 1
    
    while True:
        params = {'page': page, 'per_page': 200}
        r = requests.get(url, headers=headers, params=params).json()
        
        # If the list is empty, we've reached the end of your history
        if not r:
            break
            
        # Filter for Running only
        for activity in r:
            if activity['type'] == 'Run':
                all_runs.append({
                    'date': activity.get('start_date_local'),
                    'distance_m': activity.get('distance'),
                    'time_sec': activity.get('moving_time'),
                    'elevation_gain': activity.get('total_elevation_gain'),
                    'avg_heartrate': activity.get('average_heartrate'),
                    'max_heartrate': activity.get('max_heartrate'),
                    'avg_speed_ms': activity.get('average_speed'),
                })
        
        print(f"Processed page {page}...")
        page += 1
        
    return pd.DataFrame(all_runs)

# --- EXECUTION ---
token = get_access_token()
if token:
    df = fetch_all_running_data(token)
    
    # Simple conversion for easier Bayesian modeling
    if not df.empty:
        df['distance_km'] = df['distance_m'] / 1000
        # Convert speed to pace (min/km) - common for runners
        df['pace_min_km'] = (df['time_sec'] / 60) / df['distance_km']
        
        df.to_csv('my_strava_data.csv', index=False)
        print(f"Successfully saved {len(df)} runs to my_strava_data.csv")