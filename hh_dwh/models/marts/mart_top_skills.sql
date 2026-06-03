with staged as(
    select * from {{ ref('int_vacancies_enriched') }}
)

select 

from staged
where skills_array is not NULL
order by 