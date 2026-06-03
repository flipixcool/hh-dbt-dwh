with staged as (
    select * from {{ ref('int_vacancies_enriched') }}
),
temp as (
    select
        vacancy_id,
        professional_roles[1] as professional_role,
        experience,
        unnest(skills_array) as skill
    from staged
)
select 
    vacancy_id, 
    professional_role,
    experience,
    skill
from temp
where skill is not null