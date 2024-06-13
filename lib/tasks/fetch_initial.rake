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
        fetch_stats(web_api_client, start_date, end_date)

        generate_ratings()
        generate_lineups()
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
        sleep(1)
    end

    # If Player and PlayersBackup tables have the same data
    def players_tables_are_same()
        # Data to comapare
        players_compare = Player.order(:playerID).pluck(:firstName, :lastName, :sweaterNumber, :positionCode, :shootsCatches, :teamID).to_set
        players_backup_compare = PlayersBackup.order(:playerID).pluck(:firstName, :lastName, :sweaterNumber, :positionCode, :shootsCatches, :teamID).to_set

        return players_compare == players_backup_compare
    end

    # Fetch players(rosters)
    def fetch_players(web_api_client)
        puts "Preparing rosters for all teams..."

        # Get all active teams
        teams = Team.where(isActive: true).order(:abbrev)
        
        # Erase all data in the backup table
        PlayersBackup.delete_all

        # Populate BackupPlayers database with the roster from all active teams
        teams.each do |team|
            web_api_client.save_player_data(team, true)
        end

        # If the rosters have changed, then we fetch the players again
        if !players_tables_are_same()
            # Get rid of all previous player data from Players database
            ActiveRecord::Base.connection.execute("TRUNCATE TABLE players RESTART IDENTITY CASCADE")

            # Populate Players database with the roster from all active teams
            teams.each do |team|
                web_api_client.save_player_data(team, false)
            end
            puts "Fetched and saved players for all rosters"
        else
            puts "All rosters already loaded"
            sleep(1)
        end
    end

    # Fetch stats and prediction stats
    def fetch_stats(web_api_client, start_date, end_date)
        puts "Preparing stats for all players..."

        # Seasons to start and stop collecting stats from
        start_stat_season = 20192020
        end_stat_season = (start_date.year.to_s + end_date.year.to_s).to_i

        # Don't start collecting starts from the current season until the whole season has finished
        if Date.today < end_date
            end_stat_season = (start_date.prev_year.to_s + start_date.year.to_s).to_i
        end
        
        # If the rosters have changed, then we fetch the player stats again
        if !players_tables_are_same()
            # Populate Stats database with the stats from all players
            Player.all.each do |player|
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
        else 
            puts "All stats already loaded"
            sleep(1)
        end
    end

    # Generate offensive and defensive player ratings
    def generate_ratings()
        puts "Preparing ratings for all players..."

        ratings_generator = RatingsGenerator.new

        # Group players by team
        players_by_team = Player.all.group_by(&:teamID)

        # Iterate through each team and its associated players
        players_by_team.each do |_, team_players|
            ratings_generator.save_ratings_data(team_players)
        end
        puts "Generated and saved ratings for all players"
        sleep(1)
    end

    # Generate team lineups
    def generate_lineups()
        puts "Preparing lineups for all teams..."

        lineups_generator = LineupsGenerator.new

        # Group players by team
        players_by_team = Player.all.group_by(&:teamID)

        # If the rosters have changed, then we fetch the players again
        if !players_tables_are_same()
            # Iterate through each team and its associated players
            players_by_team.each do |team_id, team_players|
                lineups_generator.save_lineups_data(team_id, team_players)
            end
            puts "Generated and saved lineups for all teams"
        else
            puts "All lineups already loaded"
            sleep(1)
        end
    end
end