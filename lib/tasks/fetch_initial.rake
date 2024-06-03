require 'csv'
require_relative '../csv_exporter'

namespace :app do
desc "Fetch and save initial data"
    task fetch_initial: :environment do
        include CsvExporter

        step_day_interval = 7

        web_api_client = WebApiClient.new
        api_client = ApiClient.new

        start_date = Date.new(2023, 10, 1)
        end_date = Date.new(2024, 4, 30)

        # Season to start collecting stats from
        start_stat_season = 20192020
        
        # Iterate through each week of the schedule and populate Schedule database
        (start_date..end_date).step(step_day_interval) do |date|
            web_api_client.save_schedule_data(date.to_s)
            puts "Fetched and saved schedule for week #{date.to_s}"
        end

        # Populate Teams database after fetching the initial schedule
        api_client.save_team_data(start_date)
        puts "Fetched and saved all teams from the schedule"

        # Get rid of all previous player data from Players database
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE players RESTART IDENTITY CASCADE")

        # Get all active teams
        teams = Team.where(isActive: true).order(:abbrev)

        # Populate Players database with the roster from all active teams
        teams.each do |team|
            web_api_client.save_player_data(team)
            puts "Fetched and saved players from #{team.abbrev}"
        end

        # Season to stop collecting stats at
        end_stat_season = (start_date.year.to_s + end_date.year.to_s).to_i

        # Don't start collecting starts from the current season until the whole season has finished
        if Date.today < end_date
            end_stat_season = (start_date.prev_year.to_s + start_date.year.to_s).to_i
        end

        # Get all players
        players = Player.all

        puts "Preparing stats for all players..."
        # Populate Stats database with the stats from all players
        players.each do |player|
            web_api_client.save_stats_data(player.playerID, start_stat_season, end_stat_season)
        end
        puts "Fetched and saved stats for all players"

        # Create CSV's for players and stats tables for purpose of machine learning
        export_to_csv("players")
        export_to_csv("skater_stats")
        export_to_csv("goalie_stats")

        ml_client = MlClient.new
        
        puts "Preparing prediction stats for all players..."
        # Populate Stats Prediction databases with the prediction stats for all players
        ml_client.save_prediction_stats_data()
        puts "Generated and saved predicted stats for all players"
    end
end