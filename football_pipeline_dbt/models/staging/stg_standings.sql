{{ config(materialized='view') }}

with source as (
    select raw_data
    from {{ source('raw', 'RAW_STANDINGS_JSON') }}
),
standings as (
    select
        raw_data:parameters:league::string as league_id,
        raw_data:parameters:season::string as season,
        raw_data:response[0]:league:country::string as country,
        raw_data:response[0]:league:name::string as competition_name,
        raw_data:response[0]:league:season::int as competition_season,
        raw_data:response[0]:league:standings[0] as standings_array
    from source
)

select
    league_id,
    season,
    country,
    competition_name,
    competition_season,
    s.value:rank::int as rank,
    s.value:team:id::int as team_id,
    s.value:team:name::string as team_name,
    s.value:points::int as points,
    s.value:goalsDiff::int as goals_diff,
    s.value:all:played::int as played,
    s.value:all:win::int as wins,
    s.value:all:draw::int as draws,
    s.value:all:lose::int as losses,
    s.value:all:goals:for::int as goals_for,
    s.value:all:goals:against::int as goals_against,
    s.value:home:win::int as home_wins,
    s.value:home:draw::int as home_draws,
    s.value:home:lose::int as home_losses,
    s.value:away:win::int as away_wins,
    s.value:away:draw::int as away_draws,
    s.value:away:lose::int as away_losses,
    s.value:form::string as form,
    s.value:update::timestamp_tz as updated_at
from standings,
lateral flatten(input => standings_array) s