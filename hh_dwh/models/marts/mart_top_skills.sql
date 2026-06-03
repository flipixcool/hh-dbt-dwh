{{ config(materialized='view) }}

with staged as(
    select * from {{ ref('int_vacancy_skills') }}
)

select skill, count(skill) cnts 
from staged
group by skill
order by cnts desc