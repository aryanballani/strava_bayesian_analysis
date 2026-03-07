import requests

# 1. PASTE YOUR INFO HERE
CLIENT_ID = '208886'
CLIENT_SECRET = '562bbe8c0f3281bb5c233a4df42968fe208ced8e'

# 2. GENERATE THE URL
# Run this script, copy the link it prints, and paste it into your browser.
auth_url = f"https://www.strava.com/oauth/authorize?client_id={CLIENT_ID}&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=read_all,activity:read_all"

print("--- STEP 1 ---")
print("Copy and paste this URL into your browser:")
print(auth_url)
print("\n--- STEP 2 ---")
code = input("After clicking 'Authorize', copy the 'code=' value from the URL and paste it here: ")

# 3. EXCHANGE THE CODE
exchange_url = "https://www.strava.com/oauth/token"
payload = {
    'client_id': CLIENT_ID,
    'client_secret': CLIENT_SECRET,
    'code': code,
    'grant_type': 'authorization_code'
}

response = requests.post(exchange_url, data=payload)

if response.status_code == 200:
    data = response.json()
    print("\n--- SUCCESS! ---")
    print(f"YOUR NEW REFRESH TOKEN: {data['refresh_token']}")
    print("Save this Refresh Token in your main data collection script.")
else:
    print("\n--- STILL FAILING ---")
    print(response.json())