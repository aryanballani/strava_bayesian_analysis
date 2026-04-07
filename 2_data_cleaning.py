import argparse
from pathlib import Path

import pandas as pd


INPUT_CSV = Path("data/raw-data.csv")
OUTPUT_CSV = Path("data/weekly-cleaned-data.csv")


def build_weekly_dataset(input_csv: Path = INPUT_CSV) -> pd.DataFrame:
    df = pd.read_csv(input_csv)

    if df.empty:
        raise ValueError(f"{input_csv} is empty.")

    df["date"] = pd.to_datetime(df["date"], utc=True).dt.tz_convert(None)
    df = df.sort_values("date").copy()

    required_columns = ["distance_km", "time_sec", "elevation_gain"]
    missing_columns = [column for column in required_columns if column not in df.columns]
    if missing_columns:
        raise KeyError(f"Missing required columns: {missing_columns}")

    start_date = df["date"].min().normalize()
    df["week"] = ((df["date"].dt.normalize() - start_date).dt.days // 7) + 1

    weekly = (
        df.groupby("week", as_index=False)
        .agg(
            weekly_mileage=("distance_km", "sum"),
            weekly_time_sec=("time_sec", "sum"),
            weekly_elevation_gain=("elevation_gain", "sum"),
        )
    )

    all_weeks = pd.DataFrame({"week": range(1, int(df["week"].max()) + 1)})
    weekly = all_weeks.merge(weekly, on="week", how="left")

    weekly["weekly_mileage"] = weekly["weekly_mileage"].fillna(0.0)
    weekly["weekly_time_sec"] = weekly["weekly_time_sec"].fillna(0.0)
    weekly["weekly_elevation_gain"] = weekly["weekly_elevation_gain"].fillna(0.0)
    weekly["weekly_avg_pace_min_km"] = (
        weekly["weekly_time_sec"] / 60
    ).div(weekly["weekly_mileage"].where(weekly["weekly_mileage"] > 0))

    weekly = weekly[
        ["week", "weekly_mileage", "weekly_elevation_gain", "weekly_avg_pace_min_km"]
    ]

    return weekly


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Clean raw Strava run data into a weekly aggregated dataset."
    )
    parser.add_argument(
        "-i",
        "--input",
        type=Path,
        default=INPUT_CSV,
        help=f"Path to the raw input CSV. Default: {INPUT_CSV}",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=OUTPUT_CSV,
        help=f"Path to write the cleaned weekly CSV. Default: {OUTPUT_CSV}",
    )
    args = parser.parse_args()

    weekly = build_weekly_dataset(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    weekly.to_csv(args.output, index=False, float_format="%.6f")
    print(f"Wrote {len(weekly)} weekly rows to {args.output}")


if __name__ == "__main__":
    main()
