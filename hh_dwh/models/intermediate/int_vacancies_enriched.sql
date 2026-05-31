with staged as(
    select * from {{ ref('stg_vacancies') }}
)

select
    vacancy_id,
    employer,
    name,
    salary,
    salary_from,
    salary_to,
    experience,
    schedule,
    keys,
    company_description,
    area,
    professional_roles,
    specializations,
    profarea_names,
    published_at, 
    string_to_array(
        regexp_replace(keys, $r$[\[\]']$r$, '', 'g'),
        ', '
    ) as skills_array

from staged
