#!/usr/bin/env python3
"""
Unified data collection script that guides the user through obtaining a Strava
refresh token (if needed) and then downloads all running activities into
`my_strava_data.csv`.

Usage:
  python3 1_data_collection.py

It reads environment variables `STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET`,
and `STRAVA_REFRESH_TOKEN` if present, otherwise prompts interactively.
"""
import os
import requests
import pandas as pd
import sys
import argparse


def get_refresh_token_interactive(client_id: str, client_secret: str) -> str:
    """Run the authorization/code-exchange flow to obtain a refresh token."""
    auth_url = (
        f"https://www.strava.com/oauth/authorize?client_id={client_id}"
        f"&response_type=code&redirect_uri=http://localhost&approval_prompt=force"
        f"&scope=read_all,activity:read_all"
    )
    print("\n--- STEP 1: AUTHORIZE APPLICATION ---\n")
    print("Open this URL in your browser and authorize the app:\n")
    print(auth_url)
    print("\nAfter authorizing you'll be redirected to a URL containing 'code=...'.")
    code = input("Paste the value of `code=` from the redirected URL here: ").strip()

    exchange_url = "https://www.strava.com/oauth/token"
    payload = {
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
        'grant_type': 'authorization_code'
    }
    r = requests.post(exchange_url, data=payload)
    if r.status_code == 200:
        data = r.json()
        refresh = data.get('refresh_token')
        print("\nSuccess — obtained refresh token.")
        return refresh
    else:
        print("Failed to exchange code for tokens:", r.status_code, r.text)
        return None


def get_access_token(client_id: str, client_secret: str, refresh_token: str) -> str:
    url = "https://www.strava.com/oauth/token"
    payload = {
        'client_id': client_id,
        'client_secret': client_secret,
        'refresh_token': refresh_token,
        'grant_type': 'refresh_token'
    }
    r = requests.post(url, data=payload)
    if r.status_code == 200:
        return r.json().get('access_token')
    else:
        print(f"Failed to refresh token: {r.status_code} {r.text}")
        return None


def fetch_all_running_data(access_token: str) -> pd.DataFrame:
    url = "https://www.strava.com/api/v3/athlete/activities"
    headers = {'Authorization': f'Bearer {access_token}'}
    all_runs = []
    page = 1
    while True:
        params = {'page': page, 'per_page': 200}
        r = requests.get(url, headers=headers, params=params)
        if r.status_code != 200:
            print(f"Error fetching activities (page {page}): {r.status_code} {r.text}")
            break
        activities = r.json()
        if not activities:
            break
        for activity in activities:
            if activity.get('type') == 'Run':
                all_runs.append({
                    'date': activity.get('start_date_local'),
                    'distance_m': activity.get('distance'),
                    'time_sec': activity.get('moving_time'),
                    'elevation_gain': activity.get('total_elevation_gain'),
                    'avg_heartrate': activity.get('average_heartrate'),
                    'max_heartrate': activity.get('max_heartrate'),
                    'avg_speed_ms': activity.get('average_speed'),
                })
        print(f"Processed page {page} (got {len(activities)} activities) ...")
        page += 1

    return pd.DataFrame(all_runs)


def main():
    parser = argparse.ArgumentParser(description='Collect Strava running activities and save to CSV')
    parser.add_argument('-o', '--output', default='my_strava_data.csv',
                        help='Output CSV filename (default: my_strava_data.csv)')
    args = parser.parse_args()

    client_id = os.getenv('STRAVA_CLIENT_ID')
    client_secret = os.getenv('STRAVA_CLIENT_SECRET')
    refresh_token = os.getenv('STRAVA_REFRESH_TOKEN')

    print('\nUnified data collection (1_data_collection.py)')

    if not client_id:
        client_id = input('Enter STRAVA CLIENT_ID: ').strip()
    else:
        print('Using STRAVA_CLIENT_ID from environment')

    if not client_secret:
        client_secret = input('Enter STRAVA CLIENT_SECRET: ').strip()
    else:
        print('Using STRAVA_CLIENT_SECRET from environment')

    if not refresh_token:
        have = input('Do you already have a refresh token? [y/N]: ').strip().lower()
        if have == 'y':
            refresh_token = input('Paste your refresh token: ').strip()
        else:
            refresh_token = get_refresh_token_interactive(client_id, client_secret)
            if not refresh_token:
                print('Could not obtain a refresh token; exiting.')
                sys.exit(1)

    # Optionally offer to save refresh token to a .env file
    save_it = input('Save refresh token to a local .env file? [y/N]: ').strip().lower()
    if save_it == 'y':
        with open('.env', 'a') as f:
            f.write(f"STRAVA_CLIENT_ID={client_id}\n")
            f.write(f"STRAVA_CLIENT_SECRET={client_secret}\n")
            f.write(f"STRAVA_REFRESH_TOKEN={refresh_token}\n")
        print('Wrote .env (add .env to your .gitignore to keep it private).')

    print('\nExchanging refresh token for access token...')
    access = get_access_token(client_id, client_secret, refresh_token)
    if not access:
        print('Failed to obtain access token; exiting.')
        sys.exit(1)

    df = fetch_all_running_data(access)
    if df.empty:
        print('No runs found or failed to fetch runs.')
        sys.exit(0)

    # Convert and compute pace safely
    df['distance_km'] = df['distance_m'] / 1000.0
    df['pace_min_km'] = df.apply(
        lambda r: (r['time_sec'] / 60.0) / r['distance_km'] if r['distance_km'] and r['distance_km'] > 0 else None,
        axis=1
    )

    out = args.output
    df.to_csv(out, index=False)
    print(f"Successfully saved {len(df)} runs to {out}")


if __name__ == '__main__':
    main()
