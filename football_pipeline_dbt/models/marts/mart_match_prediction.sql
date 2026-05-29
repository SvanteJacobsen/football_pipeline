{{ config(materialized='table') }}

with latest_standings as (
    select *
    from {{ ref('stg_standings') }}
    qualify row_number() over (
        partition by team_id
        order by updated_at desc, points desc, goals_diff desc
    ) = 1
),

upcoming_fixtures as (
    select distinct
        fixture_id,
        fixture_date,
        competition_name,
        home_team_id,
        home_team_name,
        away_team_id,
        away_team_name
    from {{ ref('stg_fixtures') }}
    where status_short in ('NS', 'TBD', 'PST', 'CANC')
),

features as (
    select
        f.fixture_id,
        f.fixture_date,
        f.competition_name,
        f.home_team_id,
        f.home_team_name,
        f.away_team_id,
        f.away_team_name,

        coalesce(h.points, 0) as home_points,
        coalesce(a.points, 0) as away_points,

        coalesce(h.points / nullif(h.played, 0), 0) as home_points_per_game,
        coalesce(a.points / nullif(a.played, 0), 0) as away_points_per_game,

        coalesce(h.goals_diff / nullif(h.played, 0), 0) as home_goal_diff_per_game,
        coalesce(a.goals_diff / nullif(a.played, 0), 0) as away_goal_diff_per_game,

        coalesce(
            h.home_wins /
            nullif(h.home_wins + h.home_draws + h.home_losses, 0),
            0
        ) as home_home_win_rate,

        coalesce(
            a.away_wins /
            nullif(a.away_wins + a.away_draws + a.away_losses, 0),
            0
        ) as away_away_win_rate,

        coalesce(h.form, '') as home_form,
        coalesce(a.form, '') as away_form

    from upcoming_fixtures f
    left join latest_standings h
        on f.home_team_id = h.team_id
    left join latest_standings a
        on f.away_team_id = a.team_id
),

scored as (

    select
        *,

        (
            50
            + (home_points_per_game - away_points_per_game) * 10
            + (home_goal_diff_per_game - away_goal_diff_per_game) * 6
            + (home_home_win_rate - away_away_win_rate) * 8
        ) as home_bias_raw,

        (
            50
            + (away_points_per_game - home_points_per_game) * 10
            + (away_goal_diff_per_game - home_goal_diff_per_game) * 6
            + (away_away_win_rate - home_home_win_rate) * 8
        ) as away_bias_raw

    from features

),

final_scores as (

    select
        *,

        greatest(
            20,
            least(
                35,
                round(
                    30 - abs(home_bias_raw - away_bias_raw) * 0.15,
                    0
                )
            )
        ) as draw_index

    from scored

),

final as (

    select
        fixture_id,
        fixture_date,
        competition_name,
        home_team_id,
        home_team_name,
        away_team_id,
        away_team_name,
        home_points,
        away_points,
        home_points_per_game,
        away_points_per_game,
        home_goal_diff_per_game,
        away_goal_diff_per_game,
        home_home_win_rate,
        away_away_win_rate,
        home_form,
        away_form,
        home_bias_raw,
        away_bias_raw,
        draw_index,

        round(
            (100 - draw_index)
            * home_bias_raw
            / nullif(home_bias_raw + away_bias_raw, 0),
            0
        ) as home_win_index

    from final_scores

)

select
    fixture_id,
    fixture_date,
    competition_name,
    home_team_id,
    home_team_name,
    away_team_id,
    away_team_name,

    home_points,
    away_points,

    home_points_per_game,
    away_points_per_game,

    home_goal_diff_per_game,
    away_goal_diff_per_game,

    home_home_win_rate,
    away_away_win_rate,

    home_form,
    away_form,

    greatest(
        15,
        least(70, home_win_index)
    ) as home_win_index,

    draw_index,

    greatest(
        15,
        100
        - greatest(15, least(70, home_win_index))
        - draw_index
    ) as away_win_index,

    case
        when greatest(15, least(70, home_win_index))
            >= draw_index
         and greatest(15, least(70, home_win_index))
            >= greatest(
                15,
                100
                - greatest(15, least(70, home_win_index))
                - draw_index
            )
            then 'HOME'

        when draw_index
            >= greatest(15, least(70, home_win_index))
         and draw_index
            >= greatest(
                15,
                100
                - greatest(15, least(70, home_win_index))
                - draw_index
            )
            then 'DRAW'

        else 'AWAY'
    end as suggested_pick,

    current_timestamp() as loaded_at

from final