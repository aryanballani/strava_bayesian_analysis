# strava_bayesian_analysis

This repository collects running activity data from Strava and prepares a CSV dataset for downstream (Bayesian) analysis.

## Files used to create the dataset

- `get_refreh_token.py` — small helper script to obtain a Strava "refresh token" via the OAuth flow.
- `data_collection.py` — uses a refresh token to request a short-lived access token and then downloads all activities, filters for runs, and writes `my_strava_data.csv`.

## Prerequisites

- Python 3.8+ (use your virtualenv of choice)
- Install required packages:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install requests pandas
```

## Step 1 — Obtain a Strava refresh token

1. Open `get_refreh_token.py` and set your `CLIENT_ID` and `CLIENT_SECRET` values. (You can obtain these by registering an app on Strava: https://www.strava.com/settings/api)

2. Run the script and follow the printed URL. Example:

```bash
python3 get_refreh_token.py
```

3. The script will print an authorization URL. Paste it into your browser, click "Authorize", then copy the `code=` value from the redirected URL and paste it back into the script prompt.

4. If successful, the script prints a `refresh_token`. Save this value — you will need it in the next step.

Security note: Do NOT commit your client secret or refresh token to a public repository. See "Security" below.

## Step 2 — Configure `data_collection.py`

Edit `data_collection.py` and set the following values near the top of the file:

- `CLIENT_ID` — your Strava app client id
- `CLIENT_SECRET` — your Strava app client secret
- `REFRESH_TOKEN` — the refresh token obtained in Step 1

Alternative (recommended): instead of hard-coding secrets, load them from environment variables or a local, gitignored `.env` file. Example with environment variables in zsh:

```bash
export STRAVA_CLIENT_ID=208904
export STRAVA_CLIENT_SECRET=xxxxx
export STRAVA_REFRESH_TOKEN=yyyyy

# then modify data_collection.py to read from os.environ
```

## Step 3 — Run the collection script

Once `data_collection.py` is configured, run:

```bash
python3 data_collection.py
```

The script will:

- Exchange the refresh token for a short-lived access token
- Page through your athlete activities and keep only runs
- Save the resulting CSV as `my_strava_data.csv` in the repository root

If successful you'll see a message like "Successfully saved N runs to my_strava_data.csv".

## Security / Git hygiene

- Add any files that store secrets to your `.gitignore`. For example, if you create a `.env` file to hold credentials, add `.env` to `.gitignore`.
- Audit your repo history before pushing to a public remote. If credentials were accidentally committed, rotate them immediately (revoke the client secret or refresh token in your Strava settings).

## Troubleshooting

- "Failed to refresh token" from `data_collection.py`: make sure `CLIENT_ID`, `CLIENT_SECRET`, and `REFRESH_TOKEN` are correct and not expired/revoked.
- If `get_refreh_token.py` fails to exchange the authorization code, ensure the redirect URI you used when registering the app matches the `redirect_uri` in the script (it uses `http://localhost` by default).

## Notes

- The CSV produced contains columns like `date`, `distance_km`, `time_sec`, `pace_min_km`, `avg_heartrate`, `max_heartrate`, and others useful for analysis.
- Consider creating a minimal test run (a few activities) before attempting to download your entire history.