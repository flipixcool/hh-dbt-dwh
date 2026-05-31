{{ config(materialized='table') }}

with staged as(
    select * from {{ ref('int_vacancies_enriched') }}
)


select 
    name,
    round(avg(salary_from)::numeric, -1) avg_salary_from,
    round(avg(salary_to)::numeric, -1) avg_salary_to,
    count(*) count_vacancies
from staged
where salary_from is not null
group by name
order by count_vacancies desc