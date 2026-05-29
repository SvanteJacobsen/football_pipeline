{{ config(materialized='table') }}

with allsvenskan_only as (

    select *
    from {{ ref('stg_standings') }}
    where competition_name = 'Allsvenskan'

),

latest_snapshot as (

    select max(updated_at) as max_updated_at
    from allsvenskan_only

),

latest_standings as (

    select *
    from allsvenskan_only
    where updated_at = (
        select max_updated_at
        from latest_snapshot
    )

),

deduplicated as (

    select *
    from latest_standings

    qualify row_number() over (
        partition by team_id
        order by updated_at desc
    ) = 1

)

select
    season,
    country,
    competition_name,
    team_id,
    team_name,
    rank,
    points,
    played,
    wins,
    draws,
    losses,
    goals_for,
    goals_against,
    goals_diff,
    home_wins,
    home_draws,
    home_losses,
    away_wins,
    away_draws,
    away_losses,
    form,
    round(points / nullif(played, 0), 2) as points_per_game,
    updated_at,
    current_timestamp() as loaded_at

from deduplicated