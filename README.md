# hh-dbt-dwh

[Русская версия](README.ru.md)

Data Warehouse for HeadHunter vacancy analytics. Built as a compact DE/dbt project for loading raw vacancy exports into PostgreSQL, transforming them through layered dbt models, and producing analytical marts for skills, experience levels, and salary analysis.

## Architecture

```text
CSV dataset
  (data/raw/IT_vacancies_full.csv)
        ↓
  Python Loader
  - creates raw schema
  - creates raw.vacancies
  - loads data once if table is empty
        ↓
    PostgreSQL
   (raw.vacancies)
        ↓
      dbt
   staging views
   intermediate views
   mart tables
        ↓
  dbt tests + dbt docs
```

## Stack

| Tool | Version | Role |
|---|---:|---|
| PostgreSQL | 15 | Data warehouse storage |
| dbt Core | 1.8.x | SQL transformations and tests |
| dbt-postgres | 1.8.0 | PostgreSQL adapter for dbt |
| dbt-utils | package-lock | Utility macros and tests |
| Python | 3.x | Raw CSV loader |
| pandas | 2.2.2 | CSV reading |
| python-dotenv | 1.0.1 | Local environment config |
| Docker Compose | - | PostgreSQL infrastructure |

## Services & Ports

| Service | Port |
|---|---:|
| PostgreSQL | 5432 |
| dbt docs | 8080 by default |

## Prerequisites

- Docker + Docker Compose
- Python 3.x
- dbt profile directory available at `~/.dbt`
- HeadHunter vacancy CSV placed at `data/raw/IT_vacancies_full.csv`

## Quick Start

```bash
# 1. Clone
git clone https://github.com/flipixcool/hh-dbt-dwh
cd hh-dbt-dwh

# 2. Configure environment
# create .env with your PostgreSQL credentials

# 3. Start PostgreSQL
docker compose up -d

# 4. Install Python deps
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Load raw CSV into PostgreSQL
python loader/loader.py

# 6. Install dbt packages
cd hh_dwh
dbt deps

# 7. Run transformations and tests
dbt run
dbt test
```

PostgreSQL: `localhost:5432`  
dbt profile name: `hh_dwh`

Example `.env`:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=hh_dwh
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

Example `~/.dbt/profiles.yml`:

```yaml
hh_dwh:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: postgres
      password: postgres
      dbname: hh_dwh
      schema: public
      threads: 1
```

Generate dbt documentation:

```bash
dbt docs generate
dbt docs serve
```

## Data Schema

**raw.vacancies** - raw HeadHunter vacancy records loaded from CSV

| Column | Type | Description |
|---|---|---|
| Ids | INTEGER | Vacancy identifier |
| Employer | TEXT | Employer name |
| Name | TEXT | Vacancy title |
| Salary | BOOLEAN | Salary availability flag |
| From | FLOAT | Lower salary boundary |
| To | FLOAT | Upper salary boundary |
| Experience | TEXT | Required experience level |
| Schedule | TEXT | Work schedule |
| Keys | TEXT | Skills list stored as text |
| Description | TEXT | Vacancy/company description |
| Area | TEXT | Vacancy location |
| Professional roles | TEXT | Professional roles stored as text |
| Specializations | TEXT | Specialization metadata |
| Profarea names | TEXT | Professional area names |
| Published at | TIMESTAMP | Publication timestamp |

**stg_vacancies** - cleaned staging view with one row per vacancy

| Column | Description |
|---|---|
| vacancy_id | Renamed vacancy id from `Ids` |
| employer | Employer name |
| name | Vacancy title |
| salary | Salary availability flag |
| salary_from | Cleaned lower salary boundary |
| salary_to | Cleaned upper salary boundary |
| experience | Required experience |
| schedule | Work schedule |
| keys | Raw skills text |
| company_description | Description text |
| area | Vacancy location |
| professional_roles | Raw professional roles text |
| specializations | Specialization metadata |
| profarea_names | Professional area names |
| published_at | Publication timestamp |

**int_vacancies_enriched** - reusable enriched vacancy view

| Column | Description |
|---|---|
| skills_array | Parsed skills array from `keys` |
| professional_roles | Parsed professional roles array |
| other columns | Pass-through vacancy attributes from `stg_vacancies` |

**int_vacancy_skills** - normalized vacancy-skill view

| Column | Description |
|---|---|
| name | Vacancy title |
| vacancy_id | Vacancy identifier |
| professional_role | First parsed professional role |
| experience | Required experience level |
| skill | One parsed skill |

## Analytical Marts

| Mart | Grain | Description |
|---|---|---|
| mart_top_skills | one row per skill | Overall skill popularity |
| mart_backend_skills_by_experience | one row per experience and skill | Backend skill demand by experience level |
| mart_data_engineer_skills_by_experience | one row per experience and skill | Data engineering skill demand by experience level |
| mart_salary_by_role | one row per vacancy title | Average salary boundaries and vacancy count by role |

## Data Quality

The project uses dbt data tests for key modeling assumptions:

- `stg_vacancies.vacancy_id` is not null and unique.
- `int_vacancy_skills.vacancy_id` and `skill` are not null.
- `(vacancy_id, skill)` is unique in `int_vacancy_skills`.
- Mart dimensions and metrics are not null.

Current expected result:

```text
13 data tests passed
```

## Project Structure

```text
hh-dbt-dwh/
├── docker-compose.yml          # PostgreSQL service
├── requirements.txt            # Python and dbt dependencies
├── data/
│   └── raw/
│       └── IT_vacancies_full.csv
├── loader/
│   └── loader.py               # CSV -> raw.vacancies loader
└── hh_dwh/
    ├── dbt_project.yml         # dbt project config
    ├── packages.yml            # dbt packages
    ├── models/
    │   ├── staging/
    │   │   ├── sources.yml
    │   │   ├── stg_vacancies.sql
    │   │   └── stg_vacancies.yml
    │   ├── intermediate/
    │   │   ├── int_vacancies_enriched.sql
    │   │   ├── int_vacancy_skills.sql
    │   │   └── int_vacancy_skills.yml
    │   └── marts/
    │       ├── mart_top_skills.sql
    │       ├── mart_backend_skills_by_experience.sql
    │       ├── mart_data_engineer_skills_by_experience.sql
    │       ├── mart_salary_by_role.sql
    │       └── mart.yml
    ├── analyses/
    ├── macros/
    ├── seeds/
    ├── snapshots/
    └── tests/
```

## dbt Lineage

```text
raw.vacancies
    ↓
stg_vacancies
    ↓
int_vacancies_enriched
    ├── mart_salary_by_role
    ↓
int_vacancy_skills
    ├── mart_top_skills
    ├── mart_backend_skills_by_experience
    └── mart_data_engineer_skills_by_experience
```

## Portfolio Summary

This project demonstrates:

- raw-to-mart DWH modeling with PostgreSQL and dbt;
- deterministic CSV ingestion into a raw schema;
- staging cleanup and vacancy deduplication by business key;
- reusable intermediate models for parsed skills and professional roles;
- normalized vacancy-skill modeling;
- analytical marts for skills, experience, and salary analysis;
- dbt documentation and data quality tests.
