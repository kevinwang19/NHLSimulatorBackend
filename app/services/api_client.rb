require_relative "../../config/constants"

class ApiClient
    include HTTParty
    base_uri "https://api.nhle.com/stats/rest"
  
    # Get Team data from API
    def get_team_data()
        self.class.get("/en/team")
    end
    
    # Save Team data to database
    def save_team_data(start_date)
        # All team data should appear in the first 2 weeks of the season
        T

        active_teams = []
        
        # Get team data from first 2 weeks of Schedule table
        Schedule.where(date: start_date..end_date).each do |schedule|
            [schedule.awayTeamID, schedule.homeTeamID].each do |team_id|
                active_teams << team_id unless active_teams.include?(team_id)
            end
        end

        # Set isActive to false for existing teams not in the current schedule
        inactive_teams = Team.where.not(teamID: active_teams)
        inactive_teams.update_all(isActive: false)

        # Fetch additional team data and add new teams
        active_teams.each do |team_id|
            # Check if team is already in the database
            next if Team.exists?(teamID: team_id)

            # Fetch team abbreviation and logo from the schedule, skip if team is not found
            schedule = Schedule.find_by(awayTeamID: team_id) || Schedule.find_by(homeTeamID: team_id)
            next unless schedule
    
            team_abbrev = team_id == schedule.awayTeamID ? schedule.awayTeamAbbrev : schedule.homeTeamAbbrev
            team_logo = team_id == schedule.awayTeamID ? schedule.awayTeamLogo : schedule.homeTeamLogo

            response = get_team_data()

            if response.success?
                # Get additional team data from Teams API
                team_data = response.parsed_response["data"].find { |team| team["id"] == team_id }

                if team_data
                    full_name = team_data["fullName"]
                        
                    Team.create(
                        teamID: team_id,
                        fullName: full_name,
                        abbrev: team_abbrev,
                        logo: team_logo,
                        isActive: true
                    )
                else
                    Rails.logger.error "Failed to add team for #{team_id}: #{response.message}"
                end
            else
                Rails.logger.error "Failed to retrieve team for #{team_id}: #{response.message}"
            end
        end
    end
end