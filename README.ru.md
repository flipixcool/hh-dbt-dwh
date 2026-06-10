# hh-dbt-dwh

[English version](README.md)

Data Warehouse для аналитики вакансий HeadHunter на PostgreSQL и dbt.

Проект показывает простую слоистую архитектуру DWH: сырые данные загружаются в PostgreSQL, затем трансформируются через dbt, проверяются dbt-тестами и публикуются в виде аналитических витрин.

## Стек

- PostgreSQL 15
- dbt Core + dbt-postgres
- dbt-utils
- Python
- pandas
- Docker Compose

## Архитектура

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

Проект использует стандартное разделение dbt-моделей по слоям:

- `raw` хранит исходные данные HeadHunter без бизнес-трансформаций.
- `staging` переименовывает колонки, выполняет базовую очистку и дедупликацию вакансий.
- `intermediate` готовит переиспользуемые промежуточные модели для downstream-слоя.
- `marts` содержит финальные аналитические таблицы для анализа.

## Модель данных

### `stg_vacancies`

Staging-модель для сырых вакансий HeadHunter. Модель переименовывает поля и дедуплицирует записи по `vacancy_id`.

Grain модели:

```text
одна строка = одна вакансия HeadHunter
```

Проверки качества данных:

- `vacancy_id` не должен быть `null`;
- `vacancy_id` должен быть уникальным.

### `int_vacancies_enriched`

Intermediate-модель, которая подготавливает данные вакансий для downstream-моделей.

В модели парсятся текстовые поля:

- навыки в `skills_array`;
- профессиональные роли в `professional_roles`.

### `int_vacancy_skills`

Нормализованная модель “вакансия-навык”, которая используется skill-based витринами.

Grain модели:

```text
одна строка = один навык в одной вакансии
```

Проверки качества данных:

- `vacancy_id` не должен быть `null`;
- `skill` не должен быть `null`;
- комбинация `vacancy_id` и `skill` должна быть уникальной.

## Аналитические витрины

В проекте есть четыре витрины:

- `mart_top_skills`: общая популярность навыков на основе нормализованной модели `int_vacancy_skills`.
- `mart_backend_skills_by_experience`: популярные backend-навыки в разрезе опыта.
- `mart_data_engineer_skills_by_experience`: популярные data engineering навыки в разрезе опыта.
- `mart_salary_by_role`: агрегация зарплат по названию вакансии на основе enriched-слоя.

Все skill-based витрины строятся от `int_vacancy_skills`. Благодаря этому парсинг и нормализация навыков выполняются один раз и переиспользуются downstream-моделями.

## Качество данных

В проекте используются dbt data tests для проверки ключевых предположений:

- вакансии в staging-слое уникальны по `vacancy_id`;
- строки в `int_vacancy_skills` уникальны по `(vacancy_id, skill)`;
- ключевые измерения и метрики в витринах не содержат `null`.

Текущий ожидаемый результат:

```text
13 data tests passed
```

## Структура проекта

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

## Как запустить

Запустить PostgreSQL:

```bash
docker compose up -d
```

Установить Python-зависимости:

```bash
pip install -r requirements.txt
```

Создать `.env` файл с настройками подключения к PostgreSQL:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=your_database
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_password
```

Положить исходный CSV-файл с вакансиями по пути:

```text
data/raw/IT_vacancies_full.csv
```

Загрузить сырые данные в PostgreSQL:

```bash
python loader/loader.py
```

Установить dbt-пакеты:

```bash
cd hh_dwh
dbt deps
```

Настроить локальный dbt-профиль `hh_dwh` в `~/.dbt/profiles.yml`:

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

Запустить dbt-модели:

```bash
dbt run
```

Запустить dbt-тесты:

```bash
dbt test
```

Сгенерировать и открыть dbt-документацию:

```bash
dbt docs generate
dbt docs serve
```

## dbt Lineage

Граф dbt documentation показывает основной pipeline:

```text
raw.vacancies
→ stg_vacancies
→ int_vacancies_enriched
→ int_vacancy_skills
→ skill-based marts
```

`mart_salary_by_role` строится напрямую от `int_vacancies_enriched`, а skill-based витрины переиспользуют `int_vacancy_skills`.

## Что показывает проект

Проект демонстрирует:

- слоистое моделирование DWH через dbt;
- разделение моделей на staging, intermediate и marts;
- дедупликацию вакансий по бизнес-ключу;
- нормализованную модель “вакансия-навык”;
- переиспользуемый intermediate-слой;
- аналитические витрины для анализа навыков, опыта и зарплат;
- dbt-документацию и data quality tests.
