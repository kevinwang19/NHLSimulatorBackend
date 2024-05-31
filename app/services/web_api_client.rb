class WebApiClient
    include HTTParty
    base_uri "https://api-web.nhle.com/v1"
  
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

    # Get Player data from API
    def get_player_data(teamAbbrev)
        self.class.get("/roster/#{teamAbbrev}/current")
    end
  
    # Save Player data to database
    def save_player_data(team)
        position_groups = ["forwards", "defensemen", "goalies"]

        response = get_player_data(team.abbrev)
        
        if response.success?
            # Get position from each position category in the roster
            position_groups.each do |position_group|
                position_group_data = response.parsed_response
                next unless position_group_data[position_group]

                # Get player data from each position
                position_group_data[position_group].each do |player_data|
                    Player.create(
                        playerID: player_data["id"],
                        headshot: player_data["headshot"],
                        firstName: player_data["firstName"]["default"],
                        lastName: player_data["lastName"]["default"],
                        sweaterNumber: player_data["sweaterNumber"],
                        positionCode: player_data["positionCode"],
                        shootsCatches: player_data["shootsCatches"],
                        heightInInches: player_data["heightInInches"],
                        weightInPounds: player_data["weightInPounds"],
                        birthDate: player_data["birthDate"],
                        birthCountry: player_data["birthCountry"],
                        teamID: team.teamID
                    )
                end
            end
        else
            Rails.logger.error "Failed to retrieve roster for #{team.abbrev}: #{response.message}"
        end
    end

    # Get Stat data from API
    def get_stats_data(player_id)
        self.class.get("/player/#{player_id}/landing")
    end
  
    # Save Stat data to database
    def save_stats_data(player_id, end_stat_season)
        # Season to start collecting stats from
        start_stat_season = 20212022

        response = get_stats_data(player_id)

        if response.success?
            stats_data = response.parsed_response
            position = stats_data["position"]
            season_stats = stats_data.dig("seasonTotals") || []

            season_stats.each do |season_stat|
                next unless season_stat["gameTypeId"] == 2 && season_stat["leagueAbbrev"] == "NHL"
                next unless season_stat["season"] >= start_stat_season && season_stat["season"] <= end_stat_season
                if position == 'G'
                    goalie_stat = GoalieStat.find_or_initialize_by(
                        playerID: player_id,
                        season: season_stat["season"],
                        gamesPlayed: season_stat["gamesPlayed"],
                        gamesStarted: season_stat["gamesStarted"],
                        wins: season_stat["wins"],
                        losses: season_stat["losses"],
                        otLosses: season_stat["otLosses"],
                        goalsAgainst: season_stat["goalsAgainst"],
                        goalsAgainstAvg: season_stat["goalsAgainstAvg"],
                        savePctg: season_stat["savePctg"],
                        shotsAgainst: season_stat["shotsAgainst"],
                        shutouts: season_stat["shutouts"]
                    )

                    goalie_stat.save
                else
                    player_stat = PlayerStat.find_or_initialize_by(
                        playerID: player_id,
                        season: season_stat["season"],
                        gamesPlayed: season_stat["gamesPlayed"],
                        goals: season_stat["goals"],
                        assists: season_stat["assists"],
                        points: season_stat["points"],
                        avgToi: season_stat["avgToi"],
                        faceoffWinningPctg: season_stat["faceoffWinningPctg"],
                        gameWinningGoals: season_stat["gameWinningGoals"],
                        otGoals: season_stat["otGoals"],
                        pim: season_stat["pim"],
                        plusMinus: season_stat["plusMinus"],
                        powerPlayGoals: season_stat["powerPlayGoals"],
                        powerPlayPoints: season_stat["powerPlayPoints"],
                        shootingPctg: season_stat["shootingPctg"],
                        shorthandedGoals: season_stat["shorthandedGoals"],
                        shorthandedPoints: season_stat["shorthandedPoints"],
                        shots: season_stat["shots"]
                    )
                    
                    player_stat.save
                end
            end
        else
            Rails.logger.error "Failed to retrieve stats for player #{player_id}: #{response.message}"
        end
    end
end