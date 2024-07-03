require_relative "../../config/constants"

class GameSimulator
    def initialize(simulation_info)
        @simulation_info = simulation_info
        @simulation_player_stats = SimulatorPlayerStats.new
        @simulation_game_stats = SimulatorGameStats.new
        @simulation_team_stats = SimulatorTeamStats.new
    end

    # Simulate the games of a specific date
    def simulate_games(simulation_info, simulate_date)
        # Get the games to be simulated from the Schedule database using the current season, and start and end simulation dates
        current_season = Schedule.maximum(:season)
        current_date = @simulation_info.simulationCurrentDate
        games_to_simulate = Schedule.where(season: current_season).where("date >= ? AND date < ?", current_date, simulate_date)
            
        # Go through each game of the simulated dates
        games_to_simulate.each do |game|
            # Get the lineups from the away and home teams
            away_team_id = game.awayTeamID
            away_team_lineup = Lineup.where(teamID: game.awayTeamID)
            home_team_id = game.homeTeamID
            home_team_lineup = Lineup.where(teamID: game.homeTeamID)

            puts "#{Team.find_by(teamID: away_team_id).abbrev} vs #{Team.find_by(teamID: home_team_id).abbrev}"

            simulate_game(game.scheduleID, away_team_id, away_team_lineup, home_team_id, home_team_lineup)
        end
    end

    # Simulate the events and score of a game
    def simulate_game(schedule_id, away_team_id, away_team_lineup, home_team_id, home_team_lineup)
        away_team_score = 0
        away_team_pp_goals = 0
        away_team_penalties = 0
        home_team_score = 0
        home_team_pp_goals = 0
        home_team_penalties = 0
        is_away_team_penalty = false
        is_home_team_penalty = false
        penalty_min = 0
        required_ot = false

        # Get the list of goalies from both teams
        away_team_goalies = away_team_lineup.select { |player| player.position == "G" }
        home_team_goalies = home_team_lineup.select { |player| player.position == "G" }

        # Get the starting goalies of both teams
        away_team_goalie = starting_goalie(away_team_goalies)
        home_team_goalie = starting_goalie(home_team_goalies)

        # Get all players of both teams that are going to be playing
        away_players_playing = away_team_lineup.where.not(lineNumber: nil).where.not(position: "G") + away_team_goalie
        home_players_playing = home_team_lineup.where.not(lineNumber: nil).where.not(position: "G") + home_team_goalie
        all_players_playing = away_players_playing + home_players_playing

        # Record new player games played stats
        @simulation_player_stats.save_simulation_player_stats_initial(@simulation_info.simulationID, all_players_playing)

        # Simulate through 3 periods
        for period in 1..NUM_PERIODS
            # Simulate through each minute of the period
            for minute in (0...PERIOD_LENGTH_MINUTES).step(MINUTE_INCREMENTS)
                goal_stats = []
                even_strength = !is_away_team_penalty && !is_home_team_penalty

                # If there are currently no penalties, check if there will be one
                if even_strength
                    is_away_team_penalty, is_home_team_penalty = check_penalty(is_away_team_penalty, is_home_team_penalty)

                    away_team_penalties += is_away_team_penalty ? 1 : 0
                    home_team_penalties += is_home_team_penalty ? 1 : 0
                else
                    # If there is currently a penalty, keep it until it reaches 2 mins and then return back to even strength
                    if penalty_min < PENALTY_LENGTH_MINUTES
                        penalty_min += 1
                    else 
                        penalty_min = 0
                        is_away_team_penalty = false
                        is_home_team_penalty = false
                    end
                end

                even_strength = !is_away_team_penalty && !is_home_team_penalty

                # Get the current forward and defense line on the ice from both teams (set is_forward_line to true for forwards, false if not)
                away_team_fwd_line_number = line_number_on_ice(true, even_strength)
                away_team_def_line_number = line_number_on_ice(false, even_strength)
                home_team_fwd_line_number = line_number_on_ice(true, even_strength)
                home_team_def_line_number = line_number_on_ice(false, even_strength)

                forward_positions = ["C", "LW", "RW"]
                defensemen_positions = ["LD", "RD"]
                
                # If even strength, different forward and defensemen pairings can be on the ice
                away_team_regular_line = away_team_lineup.select { |player| 
                    (forward_positions.include?(player.position) && player.lineNumber == away_team_fwd_line_number) || 
                    (defensemen_positions.include?(player.position) && player.lineNumber == away_team_def_line_number)
                }
                home_team_regular_line = home_team_lineup.select { |player| 
                    (forward_positions.include?(player.position) && player.lineNumber == home_team_fwd_line_number) || 
                    (defensemen_positions.include?(player.position) && player.lineNumber == home_team_def_line_number)
                }

                # If special team, same powerplay and penalty kill forward and defensemen pairings are on the ice
                away_team_pp_line = away_team_lineup.select { |player| player.powerPlayLineNumber == away_team_fwd_line_number && player.position != "G" }
                away_team_pk_line = away_team_lineup.select { |player| player.penaltyKillLineNumber == away_team_fwd_line_number && player.position != "G" }
                home_team_pp_line = home_team_lineup.select { |player| player.powerPlayLineNumber == home_team_fwd_line_number && player.position != "G" }
                home_team_pk_line = home_team_lineup.select { |player| player.penaltyKillLineNumber == home_team_fwd_line_number && player.position != "G" }

                # Determine the current line and the offensive and defensive ratings of both teams based on the type of line on the ice
                if even_strength 
                    away_team_line = away_team_regular_line
                    home_team_line = home_team_regular_line

                    away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_regular_line, away_team_goalie)
                    home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_regular_line, home_team_goalie)
                elsif is_away_team_penalty
                    away_team_line = away_team_pk_line
                    home_team_line = home_team_pp_line

                    away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_pk_line, away_team_goalie)
                    home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_pp_line, home_team_goalie)
                else
                    away_team_line = away_team_pp_line
                    home_team_line = home_team_pk_line

                    away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_pp_line, away_team_goalie)
                    home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_pk_line, home_team_goalie)
                end

                # Determine which team has posession of the puck
                possession_team = determine_possession(away_team_regular_line, home_team_regular_line, is_away_team_penalty, is_home_team_penalty)

                # Compare ratings with randomization to determine if a shot was attempted, then if it was on net, and then if a goal was scored
                if possession_team == AWAY
                    if attempt_shot(away_team_offensive_rating, home_team_defensive_rating)
                        if shot_on_net(away_team_offensive_rating, home_team_defensive_rating)
                            # If a goal was scored, increment score and increment pp goals if scored on the powerplay
                            if score_goal(away_team_offensive_rating, home_team_defensive_rating)
                                away_team_score += 1
                                away_team_pp_goals += is_home_team_penalty ? 1 : 0

                                # Record skater stats from the goal
                                @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, away_team_line, is_home_team_penalty)

                                # Return teams back to even strength
                                penalty_min = 0
                                is_away_team_penalty = false
                                is_home_team_penalty = false
                            end
                        end
                    end
                else
                    if attempt_shot(home_team_offensive_rating, away_team_defensive_rating)
                        if shot_on_net(home_team_offensive_rating, away_team_defensive_rating)
                            # If a goal was scored, increment score and increment pp goals if scored on the powerplay
                            if score_goal(home_team_offensive_rating, away_team_defensive_rating)
                                home_team_score += 1
                                home_team_pp_goals += is_away_team_penalty ? 1 : 0

                                # Record skater stats from the goal
                                @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, home_team_line, is_away_team_penalty)

                                # Return teams back to even strength
                                penalty_min = 0
                                is_away_team_penalty = false
                                is_home_team_penalty = false
                            end
                        end
                    end
                end
            end
        end

        # If the score is still tied after 3 periods, simulate overtime
        if away_team_score == home_team_score
            required_ot = true

            # Simulate through each minute of overtime
            for minute in (0...OVERTIME_LENGTH_MINUTES).step(MINUTE_INCREMENTS)
                goal_stats = []

                # Assume special teams lines and get the line number (set is_forward_line to true as it doesn't matter for special teams)
                away_team_line_number = line_number_on_ice(true, false)
                home_team_line_number = line_number_on_ice(true, false)

                # Set the overtime lines for both teams
                away_team_ot_line = away_team_lineup.select { |player| player.otLineNumber == away_team_line_number && player.position != "G" }
                home_team_ot_line = home_team_lineup.select { |player| player.otLineNumber == home_team_line_number && player.position != "G" }
  
                # Determine the offensive and defensive ratings of both teams based on the line on the ice for overtime
                away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_ot_line, away_team_goalie)
                home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_ot_line, home_team_goalie)

                # Determine which team has posession of the puck
                possession_team = determine_possession(away_team_ot_line, home_team_ot_line, false, false)
      
                # Since overtime is higher action, compare ratings with randomization to determine if a shot was on net, and then if a goal was scored
                if possession_team == AWAY
                    if shot_on_net(away_team_offensive_rating, home_team_defensive_rating)
                        if score_goal(away_team_offensive_rating, home_team_defensive_rating)
                            away_team_score += 1

                            # Record skater stats from the goal
                            @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, away_team_line, false)

                            # End simulation if a goal is scored
                            break
                        end
                    end
                else
                    if shot_on_net(home_team_offensive_rating, away_team_defensive_rating)
                        if score_goal(home_team_offensive_rating, away_team_defensive_rating)
                            home_team_score += 1
                            
                            # Record skater stats from the goal
                            @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, home_team_line, false)
                            
                            # End simulation if a goal is scored
                            break
                        end
                    end
                end
            end
        end

        # If the score is still tied after overtime, simulate shootout
        if away_team_score == home_team_score
            # Make it a random 50/50 decision for the winner
            if rand < SHOOTOUT_WINNER_PERCENTAGE
                away_team_score += 1
            else 
                home_team_score += 1
            end
        end

        puts "Final score: #{away_team_score} - #{home_team_score}"

        # Set winning team and losing team stats and goalie stats
        if away_team_score > home_team_score
            winning_team_id = away_team_id
            winning_team_score = away_team_score
            winning_team_pp_goals = away_team_pp_goals
            winning_team_penalties = away_team_penalties

            losing_team_id = home_team_id
            losing_team_score = home_team_score
            losing_team_pp_goals = home_team_pp_goals
            losing_team_penalties = home_team_penalties

            winning_goalie = away_team_goalie
            losing_goalie = home_team_goalie
        else
            winning_team_id = home_team_id
            winning_team_score = home_team_score
            winning_team_pp_goals = home_team_pp_goals
            winning_team_penalties = home_team_penalties

            losing_team_id = away_team_id
            losing_team_score = away_team_score
            losing_team_pp_goals = away_team_pp_goals
            losing_team_penalties = away_team_penalties

            winning_goalie = home_team_goalie
            losing_goalie = away_team_goalie
        end

        # Record goalie stats from the game
        @simulation_player_stats.save_simulation_goalie_stats_win(@simulation_info.simulationID, winning_goalie, losing_team_score)
        @simulation_player_stats.save_simulation_goalie_stats_loss(@simulation_info.simulationID, losing_goalie, winning_team_score, required_ot)

        # Record game stats
        @simulation_game_stats.save_game_stats(
            @simulation_info.simulationID, 
            schedule_id, 
            away_team_id, 
            away_team_score, 
            home_team_id, 
            home_team_score
        )

        # Record team stats from the game
        @simulation_team_stats.save_team_stats_win(
            @simulation_info.simulationID,
            winning_team_id,
            winning_team_score,
            losing_team_score,
            winning_team_pp_goals,
            losing_team_penalties,
            losing_team_pp_goals,
            winning_team_penalties,
            required_ot
        )
        @simulation_team_stats.save_team_stats_loss(
            @simulation_info.simulationID,
            losing_team_id,
            losing_team_score,
            winning_team_score,
            losing_team_pp_goals,
            winning_team_penalties,
            winning_team_pp_goals,
            losing_team_penalties,
            required_ot
        )
    end

    # Starting goalie of the team based on goalie ratings
    def starting_goalie(goalies)
        # Get the goalie ratings
        goalie1 = Player.find_by(playerID: goalies[0].playerID)
        goalie2 = goalies[1] ? Player.find_by(playerID: goalies[1].playerID) : nil
        goalie1_rating = goalie1&.defensiveRating || 0
        goalie2_rating = goalie2&.defensiveRating || 0

        # Randomize which goalie starts based on the ratio of the ratings
        total_goalie_ratings = goalie1_rating + goalie2_rating
        starting_chance = rand * total_goalie_ratings
      
        return starting_chance < goalie1_rating ? goalie1 : goalie2
    end

    # Check the penalty statuses of both teams
    def check_penalty(is_away_team_penalty, is_home_team_penalty)
        # If a penalty was taken, randomize which team took it
        if is_penalty
            penalized_team = [AWAY, HOME].sample

            if penalized_team == AWAY
                is_away_team_penalty = true
                is_home_team_penalty = false
            else
                is_away_team_penalty = false
                is_home_team_penalty = true
            end
        else 
            is_away_team_penalty = false
            is_home_team_penalty = false
        end
        
        return [is_away_team_penalty, is_home_team_penalty]
    end

    # Whether or not a penalty was called
    def is_penalty
        # 15% chance of a penalty for either team
        return rand < PENALTY_CHANCE_PERCENTAGE
    end

    # Line number currently on the ice based on whether it is forwards or defensemen, and even stength or special teams
    def line_number_on_ice(is_forward_line, even_strength)
        # Assign the line numbers and probabilities of each line being on the ice based on if it is forwards or defensemen and even stength or special teams
        even_strength_line_numbers = is_forward_line ? [1, 2, 3, 4] : [1, 2, 3]
        even_strength_line_number_probabilities = is_forward_line ? [0.4, 0.3, 0.2, 0.1] : [0.5, 0.3, 0.2]
        special_teams_line_numbers = [1, 2]
        special_teams_line_number_probabilities = [0.6, 0.4]

        random_probability = rand
        cumulative_probability = 0.0

        # Iterate through the even strength or special teams lineup line by line and randomize the line on ice based on the probabilities
        if even_strength
            even_strength_line_numbers.each_with_index do |line, index|
                # Based on the randomized decimal (0-1), see which line probability it falls between
                cumulative_probability += even_strength_line_number_probabilities[index]
                return line if random_probability < cumulative_probability
            end

            return line_numbers.first
        else 
            special_teams_line_numbers.each_with_index do |line, index|
                # Based on the randomized decimal (0-1), see which line probability it falls between
                cumulative_probability += special_teams_line_number_probabilities[index]
                return line if random_probability < cumulative_probability
            end

            return line_numbers.first
        end
    end

    # Offensive or defensive rating sum of the entire line
    def determine_team_ratings(team_line, team_goalie)
        # Find the ratings of the line players in the Player database and sum them up
        player_ids = team_line.map(&:playerID)
        players = Player.where(playerID: player_ids)
        total_offensive_rating = players.sum(&:offensiveRating)
        total_defensive_rating = players.sum(&:defensiveRating) + team_goalie.defensiveRating
      
        return [total_offensive_rating, total_defensive_rating]
    end

    # Whether the away or home team has possession of the puck to determine if they have scored
    def determine_possession(away_team_line, home_team_line, is_away_team_penalty, is_home_team_penalty)
        # Home team has possession if the away team is on the penalty kill
        if is_away_team_penalty
            return HOME
        # Away team has possession if the home team is on the penalty kill
        elsif is_home_team_penalty
            return AWAY
        # If even strength, sum up the offensive and defensive ratings of all line players and use it to randomize which line has possession
        else
            away_player_ids = away_team_line.map(&:playerID)
            away_players = Player.where(playerID: away_player_ids)
            home_player_ids = home_team_line.map(&:playerID)
            home_players = Player.where(playerID: home_player_ids)

            total_away_line_rating = away_players.sum(&:offensiveRating) + away_players.sum(&:defensiveRating)
            total_home_line_rating = home_players.sum(&:offensiveRating) + home_players.sum(&:defensiveRating)
      
            total_rating = total_away_line_rating + total_home_line_rating
            possession_chance = rand * total_rating
      
            return possession_chance < total_away_line_rating ? AWAY : HOME
        end
    end

    # Whether the team has attempted a shot
    def attempt_shot(team1_offensive_rating, team2_defensive_rating)
        # Randomize shot attempt success based on the offensive rating of the team shooting and the defensive rating of the team defending
        shot_chance = rand * (team1_offensive_rating + team2_defensive_rating)
        return shot_chance < team1_offensive_rating
    end

    # Whether the team's shot has hit the net
    def shot_on_net(team1_offensive_rating, team2_defensive_rating)
        # Randomize shot on net success based on the offensive rating of the team shooting and the defensive rating of the team defending
        scoring_chance = rand * (team1_offensive_rating + team2_defensive_rating)
        return scoring_chance < team1_offensive_rating
    end
    
    # Whether the team's shot on net went in
    def score_goal(team1_offensive_rating, team2_defensive_rating)
        # Randomize goal scored success based on the offensive rating of the team shooting and the defensive rating of the team defending
        goal_chance = rand * (team1_offensive_rating + team2_defensive_rating)
        return goal_chance < team1_offensive_rating
    end
end