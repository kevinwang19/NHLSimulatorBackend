require_relative "../../config/constants"

namespace :app do
    desc "Fetch and save updated data"
    task fetch_update: :environment do
        @web_api_client = WebApiClient.new

        current_date = Time.now

        # If the current month is before September, use the previous season, otherwise use the next season
        if current_date.month < SEPTEMBER_MONTH
            current_season = (current_date.prev_year.to_s + current_date.year.to_s).to_i
        else
            current_season = (current_date.year.to_s + current_date.next_year.to_s).to_i
        end

        update_players()
        update_stats_and_ratings(current_season)
        update_lineups()
    end

    # Update players(rosters)
    def update_players()
        puts "Updating rosters for all teams..."

        # Get all active teams
        teams = Team.where(isActive: true).order(:abbrev)
        
        # Populate Players database with the roster from all active teams
        teams.each do |team|
            @web_api_client.save_player_data(team)
        end
        puts "Updated and saved players for all rosters"
    end

    # Update player stats and ratings
    def update_stats_and_ratings(current_season)
        puts "Updating stats for all players..."
        
        # Get the existing stat records of the current season from the database
        current_stats = SkaterStat.where(season: current_season) + GoalieStat.where(season: current_season)

        players = Player.all

        # Populate Stats database with the current season stats from all players
        players.each do |player|
            @web_api_client.save_stats_data(player.playerID, current_season, current_season)
        end
        puts "Updated and saved stats for all players"

        # Get the updated stat records of the current season from the database
        updated_stats = SkaterStat.where(season: current_season) + GoalieStat.where(season: current_season)

        # Get distinct players that have new stats to be used for ratings
        different_stats = updated_stats - current_stats
        different_stats_player = different_stats.map { |stat| stat[:playerID] }.uniq

        puts "Updating ratings for all players..."

        ratings_generator = RatingsGenerator.new

        # Group players by team
        players_by_team = players.group_by(&:teamID)

        # Populate Players database with the updated offensive and defensive ratings from all players in order of teams
        players_by_team.each do |_, team_players|
            ratings_generator.save_updated_ratings_data(team_players, current_season, different_stats_player)
        end
        puts "Updated and saved ratings for all players"
    end

    # Update team lineups
    def update_lineups()
        puts "Updating lineups for all teams..."

        lineups_generator = LineupsGenerator.new

        # Group players by team
        players_by_team = Player.all.group_by(&:teamID)

        # Populate Lineups database with the players, positions, and lines of each team
        players_by_team.each do |team_id, team_players|
            lineups_generator.save_lineups_data(team_id, team_players)
        end
        puts "Updated and saved lineups for all teams"
    end
end