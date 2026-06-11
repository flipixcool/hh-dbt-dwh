# hh-dbt-dwh

[English version](README.md)

Data Warehouse для аналитики вакансий HeadHunter. Проект построен как компактный DE/dbt pipeline: сырой CSV-экспорт вакансий загружается в PostgreSQL, затем данные проходят через слои dbt-моделей и публикуются в аналитические витрины по навыкам, опыту и зарплатам.

## Архитектура

```text
CSV dataset
  (data/raw/IT_vacancies_full.csv)
        ↓
  Python Loader
  - создает schema raw
  - создает raw.vacancies
  - загружает данные один раз, если таблица пустая
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

## Стек

| Инструмент | Версия | Роль |
|---|---:|---|
| PostgreSQL | 15 | Хранилище DWH |
| dbt Core | 1.8.x | SQL-трансформации и тесты |
| dbt-postgres | 1.8.0 | dbt-адаптер для PostgreSQL |
| dbt-utils | package-lock | Макросы и тесты для dbt |
| Python | 3.x | Загрузчик сырого CSV |
| pandas | 2.2.2 | Чтение CSV |
| python-dotenv | 1.0.1 | Локальная конфигурация окружения |
| Docker Compose | - | Инфраструктура PostgreSQL |

## Сервисы и порты

| Сервис | Порт |
|---|---:|
| PostgreSQL | 5432 |
| dbt docs | 8080 по умолчанию |

## Требования

- Docker + Docker Compose
- Python 3.x
- директория dbt-профилей `~/.dbt`
- CSV с вакансиями HeadHunter по пути `data/raw/IT_vacancies_full.csv`

## Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/flipixcool/hh-dbt-dwh
cd hh-dbt-dwh

# 2. Настроить окружение
# создать .env с PostgreSQL credentials

# 3. Запустить PostgreSQL
docker compose up -d

# 4. Установить Python-зависимости
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Загрузить сырой CSV в PostgreSQL
python loader/loader.py

# 6. Установить dbt-пакеты
cd hh_dwh
dbt deps

# 7. Запустить трансформации и тесты
dbt run
dbt test
```

PostgreSQL: `localhost:5432`  
dbt profile name: `hh_dwh`

Пример `.env`:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=hh_dwh
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

Пример `~/.dbt/profiles.yml`:

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

Сгенерировать dbt-документацию:

```bash
dbt docs generate
dbt docs serve
```

## Схема данных

**raw.vacancies** - сырые вакансии HeadHunter, загруженные из CSV

| Колонка | Тип | Описание |
|---|---|---|
| Ids | INTEGER | Идентификатор вакансии |
| Employer | TEXT | Работодатель |
| Name | TEXT | Название вакансии |
| Salary | BOOLEAN | Флаг наличия зарплаты |
| From | FLOAT | Нижняя граница зарплаты |
| To | FLOAT | Верхняя граница зарплаты |
| Experience | TEXT | Требуемый опыт |
| Schedule | TEXT | График работы |
| Keys | TEXT | Список навыков в текстовом виде |
| Description | TEXT | Описание вакансии/компании |
| Area | TEXT | Локация вакансии |
| Professional roles | TEXT | Профессиональные роли в текстовом виде |
| Specializations | TEXT | Метаданные специализаций |
| Profarea names | TEXT | Названия профессиональных областей |
| Published at | TIMESTAMP | Время публикации |

**stg_vacancies** - очищенный staging view, одна строка на вакансию

| Колонка | Описание |
|---|---|
| vacancy_id | Переименованный id из `Ids` |
| employer | Работодатель |
| name | Название вакансии |
| salary | Флаг наличия зарплаты |
| salary_from | Очищенная нижняя граница зарплаты |
| salary_to | Очищенная верхняя граница зарплаты |
| experience | Требуемый опыт |
| schedule | График работы |
| keys | Сырой текст с навыками |
| company_description | Описание |
| area | Локация вакансии |
| professional_roles | Сырой текст с профессиональными ролями |
| specializations | Метаданные специализаций |
| profarea_names | Названия профессиональных областей |
| published_at | Время публикации |

**int_vacancies_enriched** - переиспользуемый enriched view с подготовленными массивами

| Колонка | Описание |
|---|---|
| skills_array | Массив навыков, распарсенный из `keys` |
| professional_roles | Массив профессиональных ролей |
| other columns | Остальные атрибуты вакансии из `stg_vacancies` |

**int_vacancy_skills** - нормализованный view “вакансия-навык”

| Колонка | Описание |
|---|---|
| name | Название вакансии |
| vacancy_id | Идентификатор вакансии |
| professional_role | Первая распарсенная профессиональная роль |
| experience | Требуемый опыт |
| skill | Один распарсенный навык |

## Аналитические витрины

| Витрина | Grain | Описание |
|---|---|---|
| mart_top_skills | одна строка на навык | Общая популярность навыков |
| mart_backend_skills_by_experience | одна строка на опыт и навык | Backend-навыки по уровню опыта |
| mart_data_engineer_skills_by_experience | одна строка на опыт и навык | Data engineering навыки по уровню опыта |
| mart_salary_by_role | одна строка на название вакансии | Средние границы зарплат и количество вакансий по роли |

## Качество данных

В проекте используются dbt data tests для проверки ключевых предположений:

- `stg_vacancies.vacancy_id` не должен быть `null` и должен быть уникальным.
- `int_vacancy_skills.vacancy_id` и `skill` не должны быть `null`.
- `(vacancy_id, skill)` должен быть уникальным в `int_vacancy_skills`.
- Ключевые измерения и метрики в витринах не должны быть `null`.

Текущий ожидаемый результат:

```text
13 data tests passed
```

## Структура проекта

```text
hh-dbt-dwh/
├── docker-compose.yml          # PostgreSQL service
├── requirements.txt            # Python и dbt зависимости
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

## Что показывает проект

Проект демонстрирует:

- raw-to-mart DWH-моделирование на PostgreSQL и dbt;
- детерминированную загрузку CSV в raw schema;
- staging-очистку и дедупликацию вакансий по бизнес-ключу;
- переиспользуемые intermediate-модели для распарсенных навыков и профессиональных ролей;
- нормализованную модель “вакансия-навык”;
- аналитические витрины для навыков, опыта и зарплат;
- dbt-документацию и data quality tests.
