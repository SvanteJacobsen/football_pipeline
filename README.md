# Football Data Engineering Pipeline

## Project Overview

This project is an end-to-end football data engineering pipeline built using Azure, Snowflake, dbt, and REST API ingestion.

The pipeline ingests football data from the API-Football API, stores immutable raw snapshots in Azure Blob Storage, loads the data into Snowflake, transforms the raw JSON using dbt, and prepares the data for analytics and visualization.

The project focuses on modern cloud-native data engineering architecture and automated orchestration.

---

# Architecture

```text
API-Football
        ↓
Azure Data Factory (scheduled ingestion)
        ↓
Azure Blob Storage (raw immutable snapshots)
        ↓
Snowflake TASK (scheduled COPY INTO)
        ↓
Snowflake RAW tables
        ↓
dbt transformations
        ↓
Analytics mart
        ↓
Visualization / Dashboard
```

---

# Technologies Used

* Azure Data Factory
* Azure Blob Storage
* Snowflake
* Snowflake Tasks
* dbt
* Python
* REST API (API-Football)

---

# Features

* Automated daily ingestion
* Immutable raw snapshot storage
* Cloud-native orchestration
* Semi-structured JSON ingestion
* Scheduled Snowflake warehouse loading
* Separation of raw and transformed layers
* Parameterized ingestion architecture

---

# Data Source

Football data is sourced from:

https://www.api-football.com/

Current implementation uses:

* Allsvenskan
* Season 2025

The pipeline is parameterized and can easily be updated to future seasons.

---

# Repository Structure

```text
football-pipeline/
│
├── ingest_api_football.py
├── requirements.txt
├── README.md
│
├── raw/
│
├── .github/
│
└── dbt/
```

---

# Scheduling

## Ingestion

Azure Data Factory handles scheduled API ingestion into Azure Blob Storage.

## Warehouse Loading

Snowflake Tasks automatically load new raw JSON snapshots into Snowflake RAW tables using scheduled COPY INTO commands.

---

# Future Improvements

* Live season ingestion
* Advanced football analytics
* Predictive models
* Match outcome probabilities
* Dashboard development
* Historical trend analysis

---

# Author

Svante Jacobsen
