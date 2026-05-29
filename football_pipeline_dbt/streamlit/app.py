import pandas as pd
import streamlit as st

from snowflake_connection import get_connection


# --------------------------------------------------
# Page configuration
# --------------------------------------------------

st.set_page_config(
    page_title="Football Analytics Dashboard",
    page_icon="⚽",
    layout="wide"
)

st.title("⚽ Football Analytics Dashboard")

conn = get_connection()

# --------------------------------------------------
# LEAGUE TABLE
# --------------------------------------------------

league_query = """
SELECT *
FROM MART_TEAM_PERFORMANCE
ORDER BY rank
"""

league_df = pd.read_sql(league_query, conn)

st.header("League Table")

league_columns = [
    "RANK",
    "TEAM_NAME",
    "PLAYED",
    "POINTS",
    "GOALS_DIFF",
    "POINTS_PER_GAME",
    "FORM"
]

league_display = league_df[league_columns].copy()

league_display.columns = [
    "Rank",
    "Team",
    "Played",
    "Points",
    "Goal Difference",
    "Points / Game",
    "Form"
]

st.dataframe(
    league_display,
    use_container_width=True,
    hide_index=True
)

# --------------------------------------------------
# TEAM ANALYSIS
# --------------------------------------------------

st.header("Team Analysis")

col1, col2 = st.columns(2)

with col1:

    st.subheader("Goals Scored")

    goals_df = (
        league_df
        .sort_values("GOALS_FOR", ascending=False)
        [["TEAM_NAME", "GOALS_FOR"]]
    )

    st.bar_chart(
        goals_df.set_index("TEAM_NAME")
    )

with col2:

    st.subheader("Points Per Game")

    ppg_df = (
        league_df
        .sort_values("POINTS_PER_GAME", ascending=False)
        [["TEAM_NAME", "POINTS_PER_GAME"]]
    )

    st.bar_chart(
        ppg_df.set_index("TEAM_NAME")
    )

# --------------------------------------------------
# MATCH PREDICTION
# --------------------------------------------------

st.header("Match Prediction")

prediction_query = """
SELECT
    fixture_date,
    home_team_name,
    away_team_name,
    home_win_index,
    draw_index,
    away_win_index
FROM MART_MATCH_PREDICTION
WHERE fixture_date >= CURRENT_DATE
ORDER BY fixture_date
"""

prediction_df = pd.read_sql(
    prediction_query,
    conn
)

prediction_df.columns = [
    "Fixture Date",
    "Home Team",
    "Away Team",
    "Home Win %",
    "Draw %",
    "Away Win %"
]

st.dataframe(
    prediction_df,
    use_container_width=True,
    hide_index=True
)

conn.close()