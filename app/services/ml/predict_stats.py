import os
import sys
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from joblib import dump, load

# Prepare data of the change in stats of each age group of players
def load_and_prepare_data():
    # Load data from both databases
    players_df = pd.read_csv("csv/players.csv")
    skater_stats_df = pd.read_csv("csv/skater_stats.csv")
    goalie_stats_df = pd.read_csv("csv/goalie_stats.csv")

    # Merge data based on playerID
    merged_skater_df = pd.merge(skater_stats_df, players_df[["playerID", "birthDate"]], on="playerID", how="left")
    merged_goalie_df = pd.merge(goalie_stats_df, players_df[["playerID", "birthDate"]], on="playerID", how="left")

    # Calculate player age at the beginning of each season
    merged_skater_df["birthDate"] = pd.to_datetime(merged_skater_df["birthDate"])
    merged_skater_df["seasonStart"] = merged_skater_df["season"].astype(str).str[:4].astype(int)
    merged_skater_df["age"] = merged_skater_df["seasonStart"] - merged_skater_df["birthDate"].dt.year.astype(int)

    merged_goalie_df["birthDate"] = pd.to_datetime(merged_goalie_df["birthDate"])
    merged_goalie_df["seasonStart"] = merged_goalie_df["season"].astype(str).str[:4].astype(int)
    merged_goalie_df["age"] = merged_goalie_df["seasonStart"] - merged_goalie_df["birthDate"].dt.year.astype(int)

    # Calculate year-over-year changes in stats
    skater_stat_columns = [
        "gamesPlayed", "goals", "assists", "points", "faceoffWinningPctg",
        "gameWinningGoals", "otGoals", "pim", "plusMinus", "powerPlayGoals",
        "powerPlayPoints", "shootingPctg", "shorthandedGoals", "shorthandedPoints", "shots"
    ]
    for col in skater_stat_columns:
        merged_skater_df[f"{col}_change"] = merged_skater_df.groupby("playerID")[col].diff()

    goalie_stat_columns = [
        "gamesPlayed", "gamesStarted", "wins", "losses", "otLosses",
        "goalsAgainst", "goalsAgainstAvg", "savePctg", "shotsAgainst", "shutouts"
    ]
    for col in goalie_stat_columns:
        merged_goalie_df[f"{col}_change"] = merged_goalie_df.groupby("playerID")[col].diff()

    # Remove rows with NaN changes (first season for each player)
    merged_skater_df = merged_skater_df.dropna(subset=[f"{col}_change" for col in skater_stat_columns])
    merged_goalie_df = merged_goalie_df.dropna(subset=[f"{col}_change" for col in goalie_stat_columns])

    return merged_skater_df, merged_goalie_df, skater_stat_columns, goalie_stat_columns

# Train Linear Regression models to fit a trend of stat increases/decreases across the age groups
def train_and_save_models():
    merged_skater_df, merged_goalie_df, skater_stat_columns, goalie_stat_columns = load_and_prepare_data()

    # Prepare Features and Target
    skater_features = ["age"] + skater_stat_columns
    skater_target = [f"{col}_change" for col in skater_stat_columns]

    skater_predictor = merged_skater_df[skater_features]
    skater_response = merged_skater_df[skater_target]

    goalie_features = ["age"] + goalie_stat_columns
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
    skater_model = LinearRegression() 
    skater_model.fit(skater_predictor_train, skater_response_train)

    goalie_model = LinearRegression() #RandomForestRegressor(n_estimators=100)
    goalie_model.fit(goalie_predictor_train, goalie_response_train)
    
    # Remove existing joblib files
    skater_scaler_path = "app/services/ml/skater_scaler.joblib"
    skater_model_path = "app/services/ml/skater_model.joblib"
    goalie_scaler_path = "app/services/ml/goalie_scaler.joblib"
    goalie_model_path = "app/services/ml/goalie_model.joblib"
    
    if os.path.exists(skater_model_path):
        os.remove(skater_model_path)
    if os.path.exists(goalie_model_path):
        os.remove(goalie_model_path)
    
    # Save the scalers and the models for future use
    dump(skater_scaler, skater_scaler_path)
    dump(skater_model, skater_model_path)
    
    dump(goalie_scaler, goalie_scaler_path)
    dump(goalie_model, goalie_model_path)

# Use models to predict the player's next season stats based on their next season age
def predict_next_season(player_position, player_age, player_stats):
    # Load the scaler and the models
    skater_scaler = load("app/services/ml/skater_scaler.joblib")
    skater_model = load("app/services/ml/skater_model.joblib")
    goalie_scaler = load("app/services/ml/goalie_scaler.joblib")
    goalie_model = load("app/services/ml/goalie_model.joblib")

    # Prepare the input feature vector
    input_data = [player_age] + player_stats
    input_data_scaled = goalie_scaler.transform([input_data]) if player_position == "G" else skater_scaler.transform([input_data])

    # Select the appropriate model
    model = goalie_model if player_position == "G" else skater_model
    
    # Predict the changes
    predicted_changes = model.predict(input_data_scaled)
    
    current_index = 0
    games_played_index = 0
    skater_plusMinus_index = 8
    goalie_savePctg_index = 7

    # Calculate next season's stats
    next_season_stats = []
    for current_stat, predicted_change in zip(player_stats, predicted_changes[0]):
        # Increment by whole number if the stat is an integer
        if isinstance(current_stat, int):
            new_stat = current_stat + int(round(predicted_change))
        else:
            new_stat = current_stat + predicted_change
        
        # Make stats empty if games played is 0, make sure games played doesn't exceed 82
        if current_index == games_played_index:
            if new_stat <= 0:
                return []
            elif new_stat > 82:
                new_stat = 82
        
        # Set negative values to zero for all stats except plusMinus, make sure savePctg doesn't exceed 100%
        if new_stat > 0 or (new_stat < 0 and player_position != "G" and current_index == skater_plusMinus_index):
            if new_stat > 1 and player_position == "G" and current_index == goalie_savePctg_index:
                next_season_stats.append(1.0)
            else:
                next_season_stats.append(new_stat)
        else:
            next_season_stats.append(0)

        current_index += 1

    return next_season_stats


if __name__ == "__main__":
    action = sys.argv[1]

    if action == "train":
        train_and_save_models()
    elif action == "predict":
        player_position = sys.argv[2]
        player_age = float(sys.argv[3])
        player_stats = list(map(float, sys.argv[4:14])) if player_position == "G" else list(map(float, sys.argv[4:19]))
        predictions = predict_next_season(player_position, player_age, player_stats)
        print(",".join(map(str, predictions)))
    else:
        print(f"Unknown action: {action}")