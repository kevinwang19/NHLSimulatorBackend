require 'csv'
require_relative '../csv_exporter'

namespace :app do
desc "Fetch and save initial data"
    task fetch_initial: :environment do
        include CsvExporter

        web_api_client = WebApiClient.new
        api_client = ApiClient.new

        start_date = Date.new(2023, 10, 1)
        end_date = Date.new(2024, 4, 30)

        fetch_schedule(web_api_client, start_date, end_date)
        fetch_teams(api_client, start_date)
        fetch_players(web_api_client)
        fetch_stats_and_ratings(web_api_client, start_date, end_date)
        fetch_lineups()
    end

    # Fetch schedule
    def fetch_schedule(web_api_client, start_date, end_date)
        puts "Preparing schedule for the season..."

        # Number of days to iterate by
        step_day_interval = 7

        # Iterate through each week of the schedule and populate Schedule database
        (start_date..end_date).step(step_day_interval) do |date|
            web_api_client.save_schedule_data(date.to_s)
        end 
        puts "Fetched and saved schedule for all games"
    end
    
    # Fetch teams
    def fetch_teams(api_client, start_date)
        # Populate Teams database after fetching the initial schedule
        api_client.save_team_data(start_date)
        puts "Fetched and saved all teams from the schedule"
    end

    # Fetch players(rosters)
    def fetch_players(web_api_client)
        puts "Preparing rosters for all teams..."

        # Get all active teams
        teams = Team.where(isActive: true).order(:abbrev)
        
        # Populate Players database with the roster from all active teams
        teams.each do |team|
            web_api_client.save_player_data(team)
        end
        puts "Fetched and saved players for all rosters"
    end

    # Fetch stats, prediction stats, and player offensive and defensive ratings based on prediction stats
    def fetch_stats_and_ratings(web_api_client, start_date, end_date)
        puts "Preparing stats for all players..."

        # Seasons to start and stop collecting stats from
        start_stat_season = 20192020
        end_stat_season = (start_date.year.to_s + end_date.year.to_s).to_i

        # Don't start collecting starts from the current season until the whole season has finished
        if Date.today < end_date
            end_stat_season = (start_date.prev_year.to_s + start_date.year.to_s).to_i
        end
        
        # Get the existing stat records from the database
        current_stats = SkaterStat.all + GoalieStat.all

        players = Player.all

        # Populate Stats database with the stats from all players
        players.each do |player|
            web_api_client.save_stats_data(player.playerID, start_stat_season, end_stat_season)
        end
        puts "Fetched and saved stats for all players"

        # Get the updated stat records from the database
        updated_stats = SkaterStat.all + GoalieStat.all

        # Create CSV's for players and stats tables for purpose of machine learning
        export_to_csv("players")
        export_to_csv("skater_stats")
        export_to_csv("goalie_stats")

        ml_client = MlClient.new

        # Get distinct players that have new stats to be used for predictions
        different_stats = updated_stats - current_stats
        different_stats_player = different_stats.map { |stat| stat[:playerID] }.uniq

        puts "Preparing prediction stats for all players..."

        # Populate Stats Prediction databases with the prediction stats for all players
        ml_client.save_prediction_stats_data(different_stats_player)
        puts "Generated and saved predicted stats for all players"

        puts "Preparing ratings for all players..."

        ratings_generator = RatingsGenerator.new

        # Group players by team
        players_by_team = players.group_by(&:teamID)

        # Populate Players database with the offensive and defensive ratings from all players in order of teams
        players_by_team.each do |_, team_players|
            ratings_generator.save_ratings_data(team_players, different_stats_player)
        end
        puts "Generated and saved ratings for all players"
    end

    # Fetch team lineups
    def fetch_lineups()
        puts "Preparing lineups for all teams..."

        lineups_generator = LineupsGenerator.new

        # Group players by team
        players_by_team = Player.all.group_by(&:teamID)

        # Populate Lineups database with the players, positions, and lines of each team
        players_by_team.each do |team_id, team_players|
            lineups_generator.save_lineups_data(team_id, team_players)
        end
        puts "Generated and saved lineups for all teams"
    end
end