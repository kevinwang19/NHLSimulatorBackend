import os
import sys
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from joblib import dump, load

# Convert "hh:mm" time to a decimal
def time_in_decimal(time_str):
    minutes, seconds = map(int, time_str.split(':'))
    return minutes + (seconds / 60.0)

# Prepare data of the change in stats of each age group of players
def load_and_prepare_data():
    skater_stat_columns = [
        "gamesPlayed", "goals", "assists", "points", "avgToi", "faceoffWinningPctg",
        "gameWinningGoals", "otGoals", "pim", "plusMinus", "powerPlayGoals",
        "powerPlayPoints", "shootingPctg", "shorthandedGoals", "shorthandedPoints", "shots"
    ]
    goalie_stat_columns = [
        "gamesPlayed", "gamesStarted", "wins", "losses", "otLosses",
        "goalsAgainst", "goalsAgainstAvg", "savePctg", "shotsAgainst", "shutouts"
    ]

    # Load data from both databases
    players_df = pd.read_csv("csv/players.csv", usecols = ["playerID", "birthDate"])
    skater_stats_df = pd.read_csv("csv/skater_stats.csv", usecols = ["playerID", "season"] + skater_stat_columns)
    goalie_stats_df = pd.read_csv("csv/goalie_stats.csv", usecols = ["playerID", "season"] + goalie_stat_columns)

    # Merge data based on playerID
    merged_skater_df = skater_stats_df.merge(players_df, on="playerID", how="left")
    merged_goalie_df = goalie_stats_df.merge(players_df, on="playerID", how="left")

    # Convert skater TOI from string to int
    merged_skater_df["avgToi"] = merged_skater_df["avgToi"].apply(time_in_decimal)

    # Calculate player age at the beginning of each season
    merged_skater_df["birthDate"] = pd.to_datetime(merged_skater_df["birthDate"])
    merged_skater_df["seasonStart"] = merged_skater_df["season"].astype(str).str[:4].astype(int)
    merged_skater_df["age"] = merged_skater_df["seasonStart"] - merged_skater_df["birthDate"].dt.year.astype(int)

    merged_goalie_df["birthDate"] = pd.to_datetime(merged_goalie_df["birthDate"])
    merged_goalie_df["seasonStart"] = merged_goalie_df["season"].astype(str).str[:4].astype(int)
    merged_goalie_df["age"] = merged_goalie_df["seasonStart"] - merged_goalie_df["birthDate"].dt.year.astype(int)

    # Calculate year-over-year changes in stats as well as stats from the season prior as a reference point/baseline
    for col in skater_stat_columns:
        merged_skater_df[f"{col}_change"] = merged_skater_df.groupby("playerID")[col].diff()
        merged_skater_df[f"{col}_last_season"] = merged_skater_df.groupby("playerID")[col].shift(1)

    for col in goalie_stat_columns:
        merged_goalie_df[f"{col}_change"] = merged_goalie_df.groupby("playerID")[col].diff()
        merged_goalie_df[f"{col}_last_season"] = merged_goalie_df.groupby("playerID")[col].shift(1)

    # Fill NaN values with 0 for last season stats
    for col in skater_stat_columns:
        merged_skater_df[f"{col}_last_season"].fillna(0, inplace=True)
    
    for col in goalie_stat_columns:
        merged_goalie_df[f"{col}_last_season"].fillna(0, inplace=True)

    # Remove rows with NaN changes (first season for each player)
    merged_skater_df = merged_skater_df.dropna(subset=[f"{col}_change" for col in skater_stat_columns])
    merged_goalie_df = merged_goalie_df.dropna(subset=[f"{col}_change" for col in goalie_stat_columns])

    return merged_skater_df, merged_goalie_df, skater_stat_columns, goalie_stat_columns

# Train Linear Regression models to fit a trend of stat increases/decreases across the age groups
def train_and_save_models():
    merged_skater_df, merged_goalie_df, skater_stat_columns, goalie_stat_columns = load_and_prepare_data()

    # Prepare Features and Target
    skater_features = ["age"] + skater_stat_columns + [f"{col}_last_season" for col in skater_stat_columns]
    skater_target = [f"{col}_change" for col in skater_stat_columns]

    skater_predictor = merged_skater_df[skater_features]
    skater_response = merged_skater_df[skater_target]

    goalie_features = ["age"] + goalie_stat_columns + [f"{col}_last_season" for col in goalie_stat_columns]
    goalie_target = [f"{col}_change" for col in goalie_stat_columns]

    goalie_predictor = merged_goalie_df[goalie_features]
    goalie_response = merged_goalie_df[goalie_target]

    # Normalize features
    skater_scaler = StandardScaler()
    skater_predictor_scaled = skater_scaler.fit_transform(skater_predictor)

    goalie_scaler = StandardScaler()
    goalie_predictor_scaled = goalie_scaler.fit_transform(goalie_predictor)

    # Split data into training and testing sets
    skater_predictor_train, skater_predictor_test, skater_response_train, skater_response_test = train_test_split(skater_predictor_scaled, skater_response, test_size=0.2)
    goalie_predictor_train, goalie_predictor_test, goalie_response_train, goalie_response_test = train_test_split(goalie_predictor_scaled, goalie_response, test_size=0.2)

    # Model training using Linear Regression
    skater_model = RandomForestRegressor(n_estimators=200, max_depth=10, random_state=42) 
    skater_model.fit(skater_predictor_train, skater_response_train)

    goalie_model = RandomForestRegressor(n_estimators=200, max_depth=10, random_state=42) 
    goalie_model.fit(goalie_predictor_train, goalie_response_train)
    
    # Remove existing joblib files
    skater_scaler_path = "app/services/ml/skater_scaler.joblib"
    skater_model_path = "app/services/ml/skater_model.joblib"
    goalie_scaler_path = "app/services/ml/goalie_scaler.joblib"
    goalie_model_path = "app/services/ml/goalie_model.joblib"
    
    for path in [skater_scaler_path, skater_model_path, goalie_scaler_path, goalie_model_path]:
        if os.path.exists(path):
            os.remove(path)
    
    # Save the scalers and the models for future use
    dump(skater_scaler, skater_scaler_path)
    dump(skater_model, skater_model_path)
    
    dump(goalie_scaler, goalie_scaler_path)
    dump(goalie_model, goalie_model_path)

# Use models to predict the player's next season stats based on their next season age
def predict_next_season(player_position, player_age, player_stats, prev_season_player_stats):
    # Load the scaler and the models
    skater_scaler = load("app/services/ml/skater_scaler.joblib")
    skater_model = load("app/services/ml/skater_model.joblib")
    goalie_scaler = load("app/services/ml/goalie_scaler.joblib")
    goalie_model = load("app/services/ml/goalie_model.joblib")

    # Prepare the input feature vector, if the player has no previous stats, use the current stats as the previous stats
    input_data = [player_age] + player_stats + (player_stats if not prev_season_player_stats else prev_season_player_stats)
    input_data_scaled = goalie_scaler.transform([input_data]) if player_position == "G" else skater_scaler.transform([input_data])

    # Select the appropriate model
    model = goalie_model if player_position == "G" else skater_model
    
    # Predict the changes
    predicted_changes = model.predict(input_data_scaled)
    
    # Indexes for stats that might need to be adjusted
    current_index = 0
    gamesPlayed_index = 0
    skater_goals_index = 1
    skater_assists_index = 2
    skater_points_index = 3
    skater_plusMinus_index = 9
    goalie_gamesStarted_index = 1
    goalie_wins_index = 2
    goalie_losses_index = 3
    goalie_otLosses_index = 4
    goalie_savePctg_index = 7

    # Stats variables for calculations
    games_played = 0
    wins = 0
    losses = 0
    goals = 0        
    assists = 0

    # Calculate next season's stats
    next_season_stats = []
    for current_stat, predicted_change in zip(player_stats, predicted_changes[0]):
        # Increment by whole number if the stat is an integer
        if isinstance(current_stat, int):
            new_stat = current_stat + int(round(predicted_change))
        else:
            new_stat = current_stat + predicted_change

        if player_position == "G":
            # Goalie games played critera
            if current_index == gamesPlayed_index:
                # Only consider goalies with at least 3 games played
                if new_stat < 3:
                    return []
                # Cap games played at 82
                games_played = 82 if new_stat > 82 else new_stat
                next_season_stats.append(games_played)
            # Goalie games started critera
            elif current_index == goalie_gamesStarted_index:
                # Games started stats can't be more than games played or less than 0
                games_started = games_played if (new_stat > games_played or new_stat < 0) else new_stat
                next_season_stats.append(games_started)
            # Goalie wins criteria
            elif current_index == goalie_wins_index:
                # Losess stats can't be less than 0
                wins = 0 if new_stat < 0 else new_stat
                # Must be less than games played
                wins = games_played if wins > games_played else wins
                next_season_stats.append(wins)
            # Goalie losses criteria
            elif current_index == goalie_losses_index:
                # Losess stats can't be less than 0
                losses = 0 if new_stat < 0 else new_stat
                # Stats cannot exceed games played minus wins
                losses = games_played - wins if games_played - wins - losses <= 0 else losses
                next_season_stats.append(losses)
            # Goalie overtime losses criteria
            elif current_index == goalie_otLosses_index:
                # OT losses stats set to 0 if it exceeds games played minus wins minus losses
                ot_losses = 0 if games_played - wins - losses <= 0 else games_played - wins - losses
                next_season_stats.append(ot_losses)
            # Goalie save percentage criteria
            elif current_index == goalie_savePctg_index:
                # Save % stats can't be less than 0
                save_pctg = 0 if new_stat < 0 else new_stat
                # Stat set to max 100%
                save_pctg = 1.0 if save_pctg > 1 else save_pctg
                next_season_stats.append(save_pctg)
            # Other goalie stats criteria
            else:
                # Stat can't be less than 0
                other = 0 if new_stat < 0 else new_stat
                next_season_stats.append(other)
        else:
            # Skater games played critera
            if current_index == gamesPlayed_index:
                # Only consider skaters with at least 10 games played
                if new_stat < 10:
                    return []
                # Cap games played at 82
                games_played = 82 if new_stat > 82 else new_stat
                next_season_stats.append(games_played)
            # Skater goals criteria
            elif current_index == skater_goals_index:
                # Goals stats can't be less than 0
                goals = 0 if new_stat < 0 else new_stat
                next_season_stats.append(goals)
            # Skater assists criteria
            elif current_index == skater_assists_index:
                # Assists stats can't be less than 0
                assists = 0 if new_stat < 0 else new_stat
                next_season_stats.append(assists)
            # Skater points criteria
            elif current_index == skater_points_index:
                # Points stats set to the sum of goals and assists
                points = goals + assists
                next_season_stats.append(points)
            # Skater plus minus criteria
            elif current_index == skater_plusMinus_index:
                # Allow plus minus to be negative
                next_season_stats.append(new_stat)
            # Other skater stats criteria
            else:
                # Stat can't be less than 0
                other = 0 if new_stat < 0 else new_stat
                next_season_stats.append(other)

        current_index += 1

    return next_season_stats


if __name__ == "__main__":
    action = sys.argv[1]

    if action == "train":
        train_and_save_models()
    elif action == "predict":
        player_position = sys.argv[2]
        player_age = float(sys.argv[3])
        player_stats = list(map(float, sys.argv[4:14])) if player_position == "G" else list(map(float, sys.argv[4:20]))

        if (player_position == "G" and len(sys.argv) > 14) or (player_position != "G" and len(sys.argv) > 20):
            prev_season_player_stats = list(map(float, sys.argv[14:24])) if player_position == "G" else list(map(float, sys.argv[20:36]))
        else:
            prev_season_player_stats = []
        
        predictions = predict_next_season(player_position, player_age, player_stats, prev_season_player_stats)
        print(",".join(map(str, predictions)))
    else:
        print(f"Unknown action: {action}")