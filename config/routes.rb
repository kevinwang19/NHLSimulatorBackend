Rails.application.routes.draw do
    # Routes for schedules
    get "schedules/team_date_schedule", to: "schedules#team_date_schedule", as: "team_date_schedule"
    get "schedules/team_month_schedules", to: "schedules#team_month_schedules", as: "team_month_schedules"

    # Routes for teams
    get "teams", to: "teams#index", as: "all_teams"
    get "teams/team", to: "teams#team", as: "team"

    # Routes for players
    get "players", to: "players#index", as: "all_players"

    # Routes for skater stats
    get "skater_stats/skater_career_stats", to: "skater_stats#skater_career_stats", as: "skater_career_stats"

    # Routes for goalie stats
    get "goalie_stats/goalie_career_stats", to: "goalie_stats#goalie_career_stats", as: "goalie_career_stats"

    # Routes for skater stats predictions
    get "skater_stats_predictions/skater_predicted_stats", to: "skater_stats_predictions#skater_predicted_stats", as: "skater_predicted_stats"

    # Routes for goalie stats predictions
    get "goalie_stats_predictions/goalie_predicted_stats", to: "goalie_stats_predictions#goalie_predicted_stats", as: "goalie_predicted_stats"

    # Routes for lineups
    get "lineups", to: "lineups#index", as: "all_lineups"

    # Routes for users
    post "users", to: "users#create", as: "create_user"

    # Routes for simulations
    post "simulations", to: "simulations#create", as: "create_simulation"
    put "simulations/simulate_to_date", to: "simulations#simulate_to_date", as: "simulate_to_date"
    put "simulations/finish", to: "simulations#finish", as: "finish_simulation"
    get "simulations/user_simulation", to: "simulations#user_simulation", as: "user_recent_simulation"

    # Routes for simulation skater stats
    get "simulation_skater_stats/simulation_individual_stat", to: "simulation_skater_stats#simulation_individual_stat", as: "simulation_individual_skaterstat"
    get "simulation_skater_stats/simulation_team_stats", to: "simulation_skater_stats#simulation_team_stats", as: "simulation_team_skater_stats"
    get "simulation_skater_stats/simulation_team_position_stats", to: "simulation_skater_stats#simulation_team_position_stats", as: "simulation_team_position_stats"
  
    # Routes for simulation goalie stats
    get "simulation_goalie_stats/simulation_individual_stat", to: "simulation_goalie_stats#simulation_individual_stat", as: "simulation_individual_goalie_stat"
    get "simulation_goalie_stats/simulation_team_stats", to: "simulation_goalie_stats#simulation_team_stats", as: "simulation_team_goalie_stats"
  
    # Routes for simulation team stats
    get "simulation_team_stats/team_simulated_stats", to: "simulation_team_stats#team_simulated_stats", as: "team_simulated_stats"
    get "simulation_team_stats/simulation_all_stats", to: "simulation_team_stats#simulation_all_stats", as: "all_teams_simulated_stats"
    get "simulation_team_stats/simulation_conference_stats", to: "simulation_team_stats#simulation_conference_stats", as: "conference_teams_simulated_stats"
    get "simulation_team_stats/simulation_division_stats", to: "simulation_team_stats#simulation_division_stats", as: "division_teams_simulated_stats"

    # Routes for simulation game stats
    get "simulation_game_stats/team_simulated_game_stats", to: "simulation_game_stats#team_simulated_game_stats", as: "team_simulated_game_stats"
end
