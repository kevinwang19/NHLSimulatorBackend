class WebApiClient
    include HTTParty
    base_uri 'https://api-web.nhle.com/v1'
  
    # Get Schedule data from API
    def get_schedule_data(week_date)
        self.class.get("/schedule/#{week_date}")
    end
  
    # Save Schedule data to database
    def save_schedule_data(week_date)
        response = get_schedule_data(week_date)
        if response.success?
            game_week = response.parsed_response["gameWeek"]

            # Get games data from each day in the week
            game_week.each do |game_day|
                date = game_day["date"]
                day_abbrev = game_day["dayAbbrev"]
                
                # Get game data from each game in the day
                game_day["games"].each do |game_data|
                    # Make sure it is a regular season game
                    next unless game_data["gameType"] == 2

                    # Check if the game already exists based on all the values
                    existing_game = Schedule.find_by(
                        date: date,
                        awayTeamID: game_data["awayTeam"]["id"],
                        homeTeamID: game_data["homeTeam"]["id"]
                    )

                    unless existing_game
                        game = Schedule.find_or_initialize_by(
                            date: date,
                            dayAbbrev: day_abbrev,
                            season: game_data["season"],
                            awayTeamID: game_data["awayTeam"]["id"],
                            awayTeamAbbrev: game_data["awayTeam"]["abbrev"],
                            awayTeamLogo: game_data["awayTeam"]["logo"],
                            homeTeamID: game_data["homeTeam"]["id"],
                            homeTeamAbbrev: game_data["homeTeam"]["abbrev"],
                            homeTeamLogo: game_data["homeTeam"]["logo"],
                            score: ""
                        )
                        game.save
                    else
                        Rails.logger.info "Game already exists for #{week_date} between #{game_data["awayTeam"]["abbrev"]} and #{game_data["homeTeam"]["abbrev"]}"
                    end
                end
            end
        else
            Rails.logger.error "Failed to retrieve schedule for #{week_date}: #{response.message}"
        end
    end
end