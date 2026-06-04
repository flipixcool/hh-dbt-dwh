with staged as(
    select * from {{ ref('int_vacancy_skills') }}
)

select skill, count(skill) vacancy_count 
from staged
group by skill 
order by vacancy_count desc     