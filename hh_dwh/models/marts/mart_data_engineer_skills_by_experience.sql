with staged as (
    select * from {{ ref('int_vacancy_skills') }}
)

select 
    experience,
    skill,
    count(distinct vacancy_id) as vacancy_count
from staged
where lower(name) like '%data engineer%'
group by
    experience,
    skill
order by
    experience,
    vacancy_count desc
