with source as (
    select * from {{ source('raw', 'vacancies') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by "Ids"
            order by "Published at" desc nulls last
        ) as vacancy_row_number
    from source
    where "Ids" is not null
)


select
    "Ids" as vacancy_id,
    "Employer" as employer,
    "Name" as name,
    "Salary" as salary,
    nullif("From", 'NaN'::float) as salary_from,
    nullif("To", 'NaN'::float) as salary_to,
    "Experience" as experience,
    "Schedule" as schedule,
    "Keys" as keys,
    "Description" as company_description,
    "Area" as area,
    "Professional roles" as professional_roles,
    "Specializations" as specializations,
    "Profarea names" as profarea_names,
    "Published at" as published_at

from deduplicated
where vacancy_row_number = 1
