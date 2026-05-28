with source as (
    SELECT * from {{ source('raw', 'vacancies') }}
)


select
    "Ids" as vacancy_id,
    "Employer" as employer,
    "Name" as name,
    "Salary" as salary,
    "From" as salary_from,
    "To" as salary_to,
    "Experience" as experience,
    "Schedule" as schedule,
    "Keys" as keys,
    "Description" as company_description,
    "Area" as area,
    "Professional roles" as professional_roles,
    "Specializations" as specializations,
    "Profarea names" as profarea_names,
    "Published at" as published_at

from source
where "Ids" is not null