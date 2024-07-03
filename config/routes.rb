Rails.application.routes.draw do
    # Routes for schedules
    get "schedules", to: "schedules#index", as: "all_schedules"
    get "schedules/:schedule_id", to: "schedules#show", as: "schedule"
    get "schedules/game_schedule/:date/:away_team_id/:home_team_id", to: "schedules#game_schedule", as: "game_schedule"
    get "schedules/date_schedules/:date", to: "schedules#date_schedules", as: "date_schedules"
    get "schedules/team_season_schedules/:team_id/:season", to: "schedules#team_season_schedules", as: "team_season_schedules"

    # Routes for teams
    get "teams", to: "teams#index", as: "all_teams"
    get "teams/:team_id", to: "teams#show", as: "team"
    get "teams/abbrev_team/:abbrev", to: "teams#abbrev_team", as: "abbrev_team"

    # Routes for players
    get "players", to: "players#index", as: "all_players"
    get "players/:player_id", to: "players#show", as: "player"
    get "players/name_player/:first_name/:last_name/:player_code", to: "players#name_player", as: "name_player"
    get "players/team_players/:team_id", to: "players#team_players", as: "team_players"

    # Routes for player stats
    get "player_stats", to: "player_stats#index", as: "all_player_stats"
    get "player_stats/:position_code/:stat_id", to: "player_stats#show", as: "stat"
    get "player_stats/player_season_stats/:player_id/:season", to: "player_stats#player_season_stats", as: "player_season_stats"
    get "player_stats/player_career_stats/:player_id", to: "player_stats#player_career_stats", as: "player_career_stats"

    # Routes for stats predictions
    get "player_stats_predictions", to: "player_stats_predictions#index", as: "all_player_stats_predictions"
    get "player_stats_predictions/:position_code/:predicted_stat_id", to: "player_stats_predictions#show", as: "stat_prediction"
    get "player_stats_predictions/player_predicted_stats/:player_id", to: "player_stats_predictions#player_predicted_stats", as: "player_predicted_stats"

    # Routes for lineups
    get "lineups", to: "lineups#index", as: "all_lineups"
    get "lineups/:lineup_id", to: "lineups#show", as: "lineup"
    get "lineups/player_lineup/:player_id", to: "lineups#player_lineup", as: "player_lineup"
    get "lineups/team_lineup/:team_id", to: "lineups#team_lineup", as: "team_lineup"

    # Routes for users
    post "users", to: "users#create", as: "create_user"
    get "users", to: "users#index", as: "all_users"
    get "users/:user_id", to: "users#show", as: "user"

    # Routes for simulations
    post "simulations", to: "simulations#create", as: "create_simulation"
    post "simulations/simulate_to_date/:simulation_id/:simulate_date", to: "simulations#simulate_to_date", as: "simulate_to_date"
    put "simulations/finish/:simulation_id", to: "simulations#finish", as: "finish_simulation"
    get "simulations", to: "simulations#index", as: "all_simulations"
    get "simulations/:simulation_id", to: "simulations#show", as: "simulation"

    # Routes for simulation player stats
    post "simulation_player_stats/:simulation_id", to: "simulation_player_stats#create", as: "create_simulation_player_stats"
    get "simulation_player_stats", to: "simulation_player_stats#index", as: "all_simulation_player_stats"
    get "simulation_player_stats/:position_code/:simulation_stat_id", to: "simulation_player_stats#show", as: "simulation_player_stat"
    get "simulation_player_stats/player_simulated_stats/:simulation_id/:player_id", to: "simulation_player_stats#player_simulated_stats", as: "player_simulated_stats"
    get "simulation_player_stats/simulation_stats/:simulation_id", to: "simulation_player_stats#simulation_stats", as: "all_players_simulated_stats"
  
    # Routes for simulation team stats
    post "simulation_team_stats/:simulation_id", to: "simulation_team_stats#create", as: "create_simulation_team_stats"
    get "simulation_team_stats", to: "simulation_team_stats#index", as: "all_simulation_team_stats"
    get "simulation_team_stats/:simulation_team_stat_id", to: "simulation_team_stats#show", as: "simulation_team_stat"
    get "simulation_team_stats/team_simulated_stats/:simulation_id/:team_id", to: "simulation_team_stats#team_simulated_stats", as: "team_simulated_stats"
    get "simulation_team_stats/simulation_stats/:simulation_id", to: "simulation_team_stats#simulation_stats", as: "all_team_simulated_stats"

     # Routes for simulation game stats
     get "simulation_game_stats", to: "simulation_game_stats#index", as: "all_simulation_game_stats"
     get "simulation_game_stats/:simulation_game_stat_id", to: "simulation_game_stats#show", as: "simulation_game_stat"
     get "simulation_game_stats/game_simulated_stats/:simulation_id/:schedule_id", to: "simulation_game_stats#game_simulated_stats", as: "game_simulated_stats"
     get "simulation_game_stats/simulation_stats/:simulation_id", to: "simulation_game_stats#simulation_stats", as: "all_game_simulated_stats"
end
