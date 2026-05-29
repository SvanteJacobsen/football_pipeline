{{ config(materialized='view') }}

with source as (
    select raw_data
    from {{ source('raw', 'RAW_FIXTURES_JSON') }}
),
fixtures as (
    select
        raw_data:parameters:league::string as league_id,
        raw_data:parameters:season::string as season,
        raw_data:response as fixtures_array
    from source
)

select
    league_id,
    season,
    f.value:fixture:id::int as fixture_id,
    f.value:fixture:date::timestamp_tz as fixture_date,
    f.value:fixture:status:short::string as status_short,
    f.value:teams:home:id::int as home_team_id,
    f.value:teams:home:name::string as home_team_name,
    f.value:teams:away:id::int as away_team_id,
    f.value:teams:away:name::string as away_team_name,
    f.value:goals:home::int as home_goals,
    f.value:goals:away::int as away_goals,
    f.value:score:fulltime:home::int as fulltime_home_goals,
    f.value:score:fulltime:away::int as fulltime_away_goals,
    f.value:league:name::string as competition_name
from fixtures,
lateral flatten(input => fixtures_array) f