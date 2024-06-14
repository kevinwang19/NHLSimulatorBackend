namespace :app do
desc "Fetch and save updated data"
    task fetch_update: :environment do
        update_players()
        update_lineups()
    end

    # Update players(rosters)
    def update_players()
        puts "Updating rosters for all teams..."

        api_client = WebApiClient.new

        # Get all active teams
        teams = Team.where(isActive: true).order(:abbrev)
        
        # Populate Players database with the roster from all active teams
        teams.each do |team|
            api_client.save_player_data(team)
        end
        puts "Updated and saved players for all rosters"
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