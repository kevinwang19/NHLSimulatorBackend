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
    def get_player_data(team_abbrev)
        self.class.get("/roster/#{team_abbrev}/current")
    end
  
    # Save Player data to database
    def save_player_data(team)
        position_groups = ["forwards", "defensemen", "goalies"]
        
        # Get current team player IDs from the players database
        current_team_players_ids = Player.where(teamID: team.teamID).pluck(:playerID)
        updated_team_players_ids = []

        response = get_player_data(team.abbrev)
        
        if response.success?
            # Get position from each position category in the roster
            position_groups.each do |position_group|
                position_group_data = response.parsed_response
                next unless position_group_data[position_group]

                # Get player data from each position
                position_group_data[position_group].each do |player_data|
                    # Add new player data to the updated team players list
                    updated_team_players_ids << player_data["id"]

                    # Find if the player already exists in the database
                    existing_player = Player.find_by(playerID: player_data["id"])

                    # Update required attributes if the player exists, otherwise add the player to the database
                    if existing_player
                        # If the player exists on a different team, change his teamID to the current team
                        if existing_player.teamID != team.teamID
                            existing_player.update(teamID: team.teamID)
                        end

                        # Update personalized player attributes if they have changed
                        attribute_checks = ["headshot", "sweaterNumber", "positionCode"]
                        attribute_checks.each do |attribute|
                            if existing_player[attribute] != player_data[attribute]
                                existing_player.update(attribute => player_data[attribute])
                            end
                        end
                    else
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
            end
        else
            Rails.logger.error "Failed to retrieve roster for #{team.abbrev}: #{response.message}"
        end

        # Set current team players' teamID to nil if they are no longer on the team using playerID
        different_team_players_ids = current_team_players_ids - updated_team_players_ids
        unless different_team_players_ids.empty?
            Player.where(playerID: different_team_players_ids).update_all(teamID: nil)
        end
    end

    # Get Stat data from API
    def get_stats_data(player_id)
        self.class.get("/player/#{player_id}/landing")
    end
  
    # Save Stat data to database
    def save_stats_data(player_id, start_stat_season, end_stat_season)
        response = get_stats_data(player_id)

        if response.success?
            stats_data = response.parsed_response
            position = stats_data["position"]
            season_stats = stats_data.dig("seasonTotals") || []

            # Get stat from each season
            season_stats.each do |season_stat|
                # Only use stats from the regular season and in the NHL
                next unless season_stat["gameTypeId"] == 2 && season_stat["leagueAbbrev"] == "NHL"
                # Only use stats starting from 2021-2022 up until before the current season
                next unless season_stat["season"] >= start_stat_season && season_stat["season"] <= end_stat_season

                # Add goalie stats to the GoalieStat table and skater stats to the SkaterStat table
                if position == "G"
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
                    skater_stat = SkaterStat.find_or_initialize_by(
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
                    
                    skater_stat.save
                end
            end
        else
            Rails.logger.error "Failed to retrieve stats for player #{player_id}: #{response.message}"
        end
    end
end