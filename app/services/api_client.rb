class ApiClient
    include HTTParty
    base_uri 'https://api.nhle.com/stats/rest'
  
    # Get Team data from API
    def get_team_data()
        self.class.get("/en/team")
    end
    
    # Save Team data to database
    def save_team_data(start_date)
        # All team data should appear in the first 2 weeks of the season
        end_date = start_date + 14.days
        
        # Get team data from Schedule table
        Schedule.where(date: start_date..end_date).each do |schedule|
            [schedule.awayTeamID, schedule.homeTeamID].each do |team_id|
                # Check if team is already in the database
                next if Team.exists?(teamID: team_id)
    
                team_abbrev = team_id == schedule.awayTeamID ? schedule.awayTeamAbbrev : schedule.homeTeamAbbrev
                team_logo = team_id == schedule.awayTeamID ? schedule.awayTeamLogo : schedule.homeTeamLogo

                response = get_team_data()

                if response.success?
                    # Get additional team data from Teams API
                    team_data = response.parsed_response["data"].find { |team| team["id"] == team_id }
                    full_name = nil

                    if team_data.present?
                        full_name = team_data["fullName"]
                        
                        Team.create(
                            teamID: team_id,
                            fullName: full_name,
                            abbrev: team_abbrev,
                            logo: team_logo
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
end