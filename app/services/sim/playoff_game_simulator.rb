require_relative "../../../config/constants"

module Sim
    class PlayoffGameSimulator
        def initialize(simulation_info)
            @simulation_info = simulation_info
            @simulation_player_stats = SimulatorPlayerStats.new
            @simulation_game_stats = SimulatorGameStats.new
            @simulation_team_stats = SimulatorTeamStats.new
        end

        # Simulate the playoff games of a specific date
        def simulate_playoff_games(players_and_lineups)
            # Get the games to be simulated from the PlayoffSchedule database using the current simulationID, and start and end simulation dates
            current_date = @simulation_info.simulationCurrentDate
            games_to_simulate = PlayoffSchedule.where(simulationID: @simulation_info.simulationID).where(date: current_date)
                
            # Go through each game of the simulated dates
            games_to_simulate.each do |game|
                # Get the lineups from the away and home teams
                away_team_id = game.awayTeamID
                away_team_lineup = players_and_lineups.select { |player| player["teamID"] == away_team_id }
                home_team_id = game.homeTeamID
                home_team_lineup = players_and_lineups.select { |player| player["teamID"] == home_team_id }

                simulate_playoff_game(game.playoffScheduleID, away_team_id, away_team_lineup, home_team_id, home_team_lineup)
            end
        end

        # Simulate the events and score of a game
        def simulate_playoff_game(playoff_schedule_id, away_team_id, away_team_lineup, home_team_id, home_team_lineup)
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
            is_playoffs = true

            # Get the starting goalies of both teams
            away_team_goalie = away_team_lineup.select { |player| player["position"] == "G" && player["lineNumber"] == 1 }.first
            home_team_goalie = home_team_lineup.select { |player| player["position"] == "G" && player["lineNumber"] == 1 }.first

            # Get all players of both teams that are going to be playing
            away_players_playing = away_team_lineup.reject { |player| player["position"] == "G" || player["lineNumber"].nil? || player["lineNumber"].zero? } + [away_team_goalie]
            home_players_playing = home_team_lineup.reject { |player| player["position"] == "G" || player["lineNumber"].nil? || player["lineNumber"].zero? } + [home_team_goalie]
            all_players_playing = away_players_playing + home_players_playing

            # Record new player games played stats
            @simulation_player_stats.save_simulation_player_stats_initial(@simulation_info.simulationID, all_players_playing, is_playoffs)

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

                    # Determine the current line and the offensive and defensive ratings of both teams based on the type of line on the ice
                    if even_strength
                        # If even strength, different forward and defensemen pairings can be on the ice
                        away_team_line = away_team_lineup.select { |player| 
                            (forward_positions.include?(player["position"]) && player["lineNumber"] == away_team_fwd_line_number) || 
                            (defensemen_positions.include?(player["position"]) && player["lineNumber"] == away_team_def_line_number)
                        }
                        home_team_line = home_team_lineup.select { |player| 
                            (forward_positions.include?(player["position"]) && player["lineNumber"] == home_team_fwd_line_number) || 
                            (defensemen_positions.include?(player["position"]) && player["lineNumber"] == home_team_def_line_number)
                        }

                        away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                        home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                    elsif is_away_team_penalty
                         # If special team, same powerplay and penalty kill forward and defensemen pairings are on the ice
                        away_team_line = away_team_lineup.select { |player| player["penaltyKillLineNumber"] == away_team_fwd_line_number && player["position"] != "G" }
                        home_team_line = home_team_lineup.select { |player| player["powerPlayLineNumber"] == home_team_fwd_line_number && player["position"] != "G" }

                        away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                        home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                    else
                         # If special team, same powerplay and penalty kill forward and defensemen pairings are on the ice
                        away_team_line = away_team_lineup.select { |player| player["powerPlayLineNumber"] == away_team_fwd_line_number && player["position"] != "G" }
                        home_team_line = home_team_lineup.select { |player| player["penaltyKillLineNumber"] == home_team_fwd_line_number && player["position"] != "G" }

                        away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                        home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                    end

                    # Determine which team has posession of the puck
                    possession_team = determine_possession(away_team_line, home_team_line, is_away_team_penalty, is_home_team_penalty)

                    # Compare ratings with randomization to determine if a shot was attempted, then if it was on net, and then if a goal was scored
                    if possession_team == AWAY
                        if attempt_shot(away_team_offensive_rating, home_team_defensive_rating)
                            if shot_on_net(away_team_offensive_rating, home_team_defensive_rating)
                                # If a goal was scored, increment score and increment pp goals if scored on the powerplay
                                if score_goal(away_team_offensive_rating, home_team_defensive_rating)
                                    away_team_score += 1
                                    away_team_pp_goals += is_home_team_penalty ? 1 : 0

                                    # Record skater stats from the goal
                                    @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, away_team_line, is_home_team_penalty, is_playoffs)

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
                                    @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, home_team_line, is_away_team_penalty, is_playoffs)

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
                while away_team_score == home_team_score
                    # Simulate through each minute of the overtime period
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

                        # Determine the current line and the offensive and defensive ratings of both teams based on the type of line on the ice
                        if even_strength
                            # If even strength, different forward and defensemen pairings can be on the ice
                            away_team_line = away_team_lineup.select { |player| 
                                (forward_positions.include?(player["position"]) && player["lineNumber"] == away_team_fwd_line_number) || 
                                (defensemen_positions.include?(player["position"]) && player["lineNumber"] == away_team_def_line_number)
                            }
                            home_team_line = home_team_lineup.select { |player| 
                                (forward_positions.include?(player["position"]) && player["lineNumber"] == home_team_fwd_line_number) || 
                                (defensemen_positions.include?(player["position"]) && player["lineNumber"] == home_team_def_line_number)
                            }

                            away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                            home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                        elsif is_away_team_penalty
                            # If special team, same powerplay and penalty kill forward and defensemen pairings are on the ice
                            away_team_line = away_team_lineup.select { |player| player["penaltyKillLineNumber"] == away_team_fwd_line_number && player["position"] != "G" }
                            home_team_line = home_team_lineup.select { |player| player["powerPlayLineNumber"] == home_team_fwd_line_number && player["position"] != "G" }

                            away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                            home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                        else
                            # If special team, same powerplay and penalty kill forward and defensemen pairings are on the ice
                            away_team_line = away_team_lineup.select { |player| player["powerPlayLineNumber"] == away_team_fwd_line_number && player["position"] != "G" }
                            home_team_line = home_team_lineup.select { |player| player["penaltyKillLineNumber"] == home_team_fwd_line_number && player["position"] != "G" }

                            away_team_offensive_rating, away_team_defensive_rating = determine_team_ratings(away_team_line, away_team_goalie)
                            home_team_offensive_rating, home_team_defensive_rating = determine_team_ratings(home_team_line, home_team_goalie)
                        end

                        # Determine which team has posession of the puck
                        possession_team = determine_possession(away_team_line, home_team_line, is_away_team_penalty, is_home_team_penalty)

                        # Compare ratings with randomization to determine if a shot was attempted, then if it was on net, and then if a goal was scored
                        if possession_team == AWAY
                            if attempt_shot(away_team_offensive_rating, home_team_defensive_rating)
                                if shot_on_net(away_team_offensive_rating, home_team_defensive_rating)
                                    # If a goal was scored, increment score and increment pp goals if scored on the powerplay
                                    if score_goal(away_team_offensive_rating, home_team_defensive_rating)
                                        away_team_score += 1
                                        away_team_pp_goals += is_home_team_penalty ? 1 : 0

                                        # Record skater stats from the goal
                                        @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, away_team_line, is_home_team_penalty, is_playoffs)

                                        # End simulation if a goal is scored
                                        break
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
                                        @simulation_player_stats.simulate_skater_stats(@simulation_info.simulationID, home_team_line, is_away_team_penalty, is_playoffs)

                                        # End simulation if a goal is scored
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

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
            @simulation_player_stats.save_simulation_goalie_stats_win(@simulation_info.simulationID, winning_goalie, losing_team_score, is_playoffs)
            @simulation_player_stats.save_simulation_goalie_stats_loss(@simulation_info.simulationID, losing_goalie, winning_team_score, required_ot, is_playoffs)

            # Record game stats
            @simulation_game_stats.save_playoff_game_stats(
                playoff_schedule_id,
                away_team_score,
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
                is_playoffs
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
                required_ot,
                is_playoffs
            )
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
            # 8% chance of a penalty for either team
            return rand < PENALTY_CHANCE_PERCENTAGE
        end

        # Line number currently on the ice based on whether it is forwards or defensemen, and even stength or special teams
        def line_number_on_ice(is_forward_line, even_strength)
            # Assign the line numbers and probabilities of each line being on the ice based on if it is forwards or defensemen and even stength or special teams
            even_strength_line_numbers = is_forward_line ? [1, 2, 3, 4] : [1, 2, 3]
            even_strength_line_number_probabilities = is_forward_line ? [0.35, 0.3, 0.2, 0.15] : [0.4, 0.35, 0.25]
            special_teams_line_numbers = [1, 2]
            special_teams_line_number_probabilities = [0.65, 0.35]

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
            # Sum up the offensive and defensive ratings
            total_offensive_rating = team_line.sum { |player| player["offensiveRating"] * 100 }
            total_defensive_rating = team_line.sum { |player| player["defensiveRating"] * 100 } + team_goalie["defensiveRating"] * 100
        
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
                total_away_line_rating = away_team_line.sum { |player| player["offensiveRating"] * 100 } + away_team_line.sum { |player| player["defensiveRating"] * 100 }
                total_home_line_rating = home_team_line.sum { |player| player["offensiveRating"] * 100 } + home_team_line.sum { |player| player["defensiveRating"] * 100 }
        
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
end