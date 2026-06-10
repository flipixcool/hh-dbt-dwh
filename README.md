# hh-dbt-dwh

[Русская версия](README.ru.md)

Data Warehouse for HeadHunter vacancy analytics built with PostgreSQL and dbt.

The project demonstrates a simple layered DWH architecture for job market analysis: raw data is loaded into PostgreSQL, transformed with dbt, tested with dbt data tests, and exposed through analytical marts.

## Stack

- PostgreSQL 15
- dbt Core with dbt-postgres
- dbt-utils
- Python
- pandas
- Docker Compose

## Architecture

```text
raw.vacancies
    ↓
stg_vacancies
    ↓
int_vacancies_enriched
    ↓
int_vacancy_skills
    ↓
marts
```

The project follows a standard dbt layering approach:

- `raw` stores the original HeadHunter vacancy data.
- `staging` renames columns, applies basic cleanup, and deduplicates vacancies.
- `intermediate` prepares reusable business entities for downstream models.
- `marts` contains final analytical tables for reporting and analysis.

## Data Model

### `stg_vacancies`

Staging model for raw HeadHunter vacancies. It renames raw columns and deduplicates records by `vacancy_id`.

Grain:

```text
one row = one HeadHunter vacancy
```

Data quality checks:

- `vacancy_id` is not null
- `vacancy_id` is unique

### `int_vacancies_enriched`

Intermediate model that prepares vacancy data for downstream transformations.

It parses text fields into arrays:

- skills into `skills_array`
- professional roles into `professional_roles`

### `int_vacancy_skills`

Normalized vacancy-skill model used by skill-based marts.

Grain:

```text
one row = one skill in one vacancy
```

Data quality checks:

- `vacancy_id` is not null
- `skill` is not null
- combination of `vacancy_id` and `skill` is unique

## Analytical Marts

The project currently contains four marts:

- `mart_top_skills`: overall skill popularity based on normalized vacancy-skill data.
- `mart_backend_skills_by_experience`: top backend skills grouped by experience level.
- `mart_data_engineer_skills_by_experience`: top data engineering skills grouped by experience level.
- `mart_salary_by_role`: salary aggregation by vacancy name based on enriched vacancy data.

Skill-based marts are built from `int_vacancy_skills`, so skill parsing and normalization are implemented once and reused downstream.

## Data Quality

The project uses dbt data tests to validate key assumptions:

- staging vacancies are unique by `vacancy_id`;
- normalized vacancy-skill rows are unique by `(vacancy_id, skill)`;
- key mart dimensions and metrics are not null.

Current expected test result:

```text
13 data tests passed
```

## Project Structure

```text
.
├── docker-compose.yml
├── loader/
│   └── loader.py
├── hh_dwh/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── packages.yml
│   └── package-lock.yml
└── requirements.txt
```

## How to Run

Start PostgreSQL:

```bash
docker compose up -d
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Create a `.env` file with PostgreSQL connection settings:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=your_database
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_password
```

Place the raw vacancy dataset at:

```text
data/raw/IT_vacancies_full.csv
```

Load raw data into PostgreSQL:

```bash
python loader/loader.py
```

Install dbt packages:

```bash
cd hh_dwh
dbt deps
```

Configure a local dbt profile named `hh_dwh` in `~/.dbt/profiles.yml`:

```yaml
hh_dwh:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: your_user
      password: your_password
      dbname: your_database
      schema: public
      threads: 1
```

Run dbt models:

```bash
dbt run
```

Run dbt tests:

```bash
dbt test
```

Generate and serve dbt documentation:

```bash
dbt docs generate
dbt docs serve
```

## dbt Lineage

The dbt documentation graph shows the main pipeline:

```text
raw.vacancies
→ stg_vacancies
→ int_vacancies_enriched
→ int_vacancy_skills
→ skill-based marts
```

`mart_salary_by_role` is built directly from `int_vacancies_enriched`, while skill-based marts reuse `int_vacancy_skills`.

## Portfolio Summary

This project demonstrates:

- layered DWH modeling with dbt;
- staging, intermediate, and mart layers;
- vacancy deduplication by business key;
- normalized vacancy-skill modeling;
- reusable intermediate models;
- analytical marts for skills, experience, and salary analysis;
- dbt documentation and data quality tests.
