import json
import os
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv
from azure.storage.blob import BlobServiceClient, ContentSettings


BASE_URL = "https://v3.football.api-sports.io"
COUNTRY = "Sweden"
LEAGUE_NAME = "Allsvenskan"
SEASON = 2024  # keep the season that works for your plan right now
RAW_DIR = Path("raw")


def utc_now_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def fetch_api_football(endpoint: str, params: dict, api_key: str) -> dict:
    url = f"{BASE_URL}/{endpoint}"
    headers = {"x-apisports-key": api_key}

    response = requests.get(url, headers=headers, params=params, timeout=60)
    response.raise_for_status()

    payload = response.json()

    if payload.get("errors"):
        raise RuntimeError(
            f"API-Football returned errors for {endpoint}: {payload['errors']}"
        )

    return payload


def get_league_id(api_key: str) -> int:
    data = fetch_api_football(
        "leagues",
        {"country": COUNTRY, "season": SEASON},
        api_key,
    )

    for item in data.get("response", []):
        league = item.get("league", {})
        if league.get("name", "").lower() == LEAGUE_NAME.lower():
            return league["id"]

    raise RuntimeError(
        f"Could not find {LEAGUE_NAME} in {COUNTRY} for season {SEASON}."
    )


def save_raw_json(data: dict, subfolder: str, name: str) -> Path:
    folder = RAW_DIR / subfolder
    ensure_dir(folder)

    filename = f"{utc_now_stamp()}_{name}.json"
    filepath = folder / filename

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    return filepath


def upload_to_azure(
    local_path: Path,
    container_name: str,
    connection_string: str,
    blob_path: str,
) -> None:
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    try:
        container_client.create_container()
    except Exception:
        pass

    blob_client = container_client.get_blob_client(blob_path)

    with open(local_path, "rb") as data:
        blob_client.upload_blob(
            data,
            overwrite=True,
            content_settings=ContentSettings(content_type="application/json"),
        )


def main() -> None:
    load_dotenv()

    api_key = os.getenv("API_FOOTBALL_KEY")
    azure_conn_str = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    container_name = os.getenv("AZURE_BLOB_CONTAINER", "raw-football")

    if not api_key:
        raise ValueError("Missing API_FOOTBALL_KEY in .env")
    if not azure_conn_str:
        raise ValueError("Missing AZURE_STORAGE_CONNECTION_STRING in .env")

    league_id = get_league_id(api_key)
    print(f"Using league id {league_id} for {LEAGUE_NAME}")

    jobs = [
        {
            "endpoint": "standings",
            "params": {"league": league_id, "season": SEASON},
            "subfolder": "standings",
            "name": f"standings_{LEAGUE_NAME.lower().replace(' ', '_')}_season_{SEASON}",
        },
        {
            "endpoint": "fixtures",
            "params": {
                "league": league_id,
                "season": SEASON,
                "status": "FT-AET-PEN",
            },
            "subfolder": "fixtures_completed",
            "name": f"fixtures_completed_{LEAGUE_NAME.lower().replace(' ', '_')}_season_{SEASON}",
        },
    ]

    for job in jobs:
        print(f"Fetching {job['endpoint']} ...")
        data = fetch_api_football(job["endpoint"], job["params"], api_key)

        local_path = save_raw_json(data, job["subfolder"], job["name"])
        print(f"Saved locally: {local_path}")

        blob_path = f"raw/api_football/{job['subfolder']}/{local_path.name}"
        upload_to_azure(local_path, container_name, azure_conn_str, blob_path)
        print(f"Uploaded to Azure Blob: {blob_path}")

    print("Done.")


if __name__ == "__main__":
    main()