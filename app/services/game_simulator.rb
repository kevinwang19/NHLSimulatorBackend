class GameSimulator
    AWAY = "away"
    HOME = "home"
    NUM_PERIODS = 3
    PERIOD_LENGTH_MINUTES = 20
    OVERTIME_LENGTH_MINUTES = 5
    MINUTE_INCREMENTS = 1

    # Simulate the games of a specific date
    def simulate_games(games, teams, players)
        # Go through each game of the specific date
        games.each do |game|
            # Get the lineups from the away and home teams
            away_team_id = game.awayTeamID
            away_team_lineup = Lineup.where(teamID: game.awayTeamID)
            home_team_id = game.homeTeamID
            home_team_lineup = Lineup.where(teamID: game.homeTeamID)

            puts "#{Team.find_by(teamID: away_team_id).abbrev} vs #{Team.find_by(teamID: home_team_id).abbrev}"

            simulate_game(away_team_lineup, home_team_lineup, teams, away_team_id, home_team_id, players)
        end
    end

    # Simulate the events and score of a game
    def simulate_game(away_team_lineup, home_team_lineup, teams, away_id, home_id, players)
        away_team_score = 0
        home_team_score = 0
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

        # Simulate through 3 periods
        for period in 1..NUM_PERIODS
            # Simulate through each minute of the period
            for minute in (0...PERIOD_LENGTH_MINUTES).step(MINUTE_INCREMENTS)
                goal_stats = []
                even_strength = !is_away_team_penalty && !is_home_team_penalty

                # If there are currently no penalties, check if there will be one
                if even_strength
                    is_away_team_penalty, is_home_team_penalty = check_penalty(is_away_team_penalty, is_home_team_penalty)
                else
                    # If there is currently a penalty, keep it until it reaches 2 mins and then return back to even strength
                    if penalty_min < 2
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
                            # If a goal was scored, increment score
                            if score_goal(away_team_offensive_rating, home_team_defensive_rating)
                                away_team_score += 1
                                # Determine who scored the goal and got the assists
                                goal_stats = determine_goal_stats(away_team_line)

                                goal_stats.each_with_index do |stat, index|
                                    if index == 0
                                        if players.has_key?("#{stat.firstName}_#{stat.lastName}_goals")
                                            players["#{stat.firstName}_#{stat.lastName}_goals"] += 1
                                        else
                                            players["#{stat.firstName}_#{stat.lastName}_goals"] = 1
                                        end
                                    else 
                                        if players.has_key?("#{stat.firstName}_#{stat.lastName}_assists")
                                            players["#{stat.firstName}_#{stat.lastName}_assists"] += 1
                                        else
                                            players["#{stat.firstName}_#{stat.lastName}_assists"] = 1
                                        end
                                    end
                                end

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
                            # If a goal was scored, increment score
                            if score_goal(home_team_offensive_rating, away_team_defensive_rating)
                                home_team_score += 1
                                # Determine who scored the goal and got the assists
                                goal_stats = determine_goal_stats(home_team_line)

                                goal_stats.each_with_index do |stat, index|
                                    if index == 0
                                        if players.has_key?("#{stat.firstName}_#{stat.lastName}_goals")
                                            players["#{stat.firstName}_#{stat.lastName}_goals"] += 1
                                        else
                                            players["#{stat.firstName}_#{stat.lastName}_goals"] = 1
                                        end
                                    else 
                                        if players.has_key?("#{stat.firstName}_#{stat.lastName}_assists")
                                            players["#{stat.firstName}_#{stat.lastName}_assists"] += 1
                                        else
                                            players["#{stat.firstName}_#{stat.lastName}_assists"] = 1
                                        end
                                    end
                                end

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
                            # Determine who scored the goal and got the assists
                            goal_stats = determine_goal_stats(away_team_ot_line)

                            goal_stats.each_with_index do |stat, index|
                                if index == 0
                                    if players.has_key?("#{stat.firstName}_#{stat.lastName}_goals")
                                        players["#{stat.firstName}_#{stat.lastName}_goals"] += 1
                                    else
                                        players["#{stat.firstName}_#{stat.lastName}_goals"] = 1
                                    end
                                else 
                                    if players.has_key?("#{stat.firstName}_#{stat.lastName}_assists")
                                        players["#{stat.firstName}_#{stat.lastName}_assists"] += 1
                                    else
                                        players["#{stat.firstName}_#{stat.lastName}_assists"] = 1
                                    end
                                end
                            end

                            # End simulation if a goal is scored
                            break
                        end
                    end
                else
                    if shot_on_net(home_team_offensive_rating, away_team_defensive_rating)
                        if score_goal(home_team_offensive_rating, away_team_defensive_rating)
                            home_team_score += 1
                            # Determine who scored the goal and got the assists
                            goal_stats = determine_goal_stats(home_team_ot_line)

                            goal_stats.each_with_index do |stat, index|
                                if index == 0
                                    if players.has_key?("#{stat.firstName}_#{stat.lastName}_goals")
                                        players["#{stat.firstName}_#{stat.lastName}_goals"] += 1
                                    else
                                        players["#{stat.firstName}_#{stat.lastName}_goals"] = 1
                                    end
                                else 
                                    if players.has_key?("#{stat.firstName}_#{stat.lastName}_assists")
                                        players["#{stat.firstName}_#{stat.lastName}_assists"] += 1
                                    else
                                        players["#{stat.firstName}_#{stat.lastName}_assists"] = 1
                                    end
                                end
                            end
                            
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
            if rand < 0.5
                away_team_score += 1
            else 
                home_team_score += 1
            end
        end

        puts "Final score: #{away_team_score} - #{home_team_score}"


        away_team = Team.find_by(teamID: away_id)
        home_team = Team.find_by(teamID: home_id)
        if away_team_score > home_team_score 
            if teams.has_key?("#{away_team.abbrev}_wins")
                teams["#{away_team.abbrev}_wins"] += 1
            else
                teams["#{away_team.abbrev}_wins"] = 1
            end
            
            if teams.has_key?("#{home_team.abbrev}_losses")
                teams["#{home_team.abbrev}_losses"] += 1
            else
                teams["#{home_team.abbrev}_losses"] = 1
            end
        else 
            if teams.has_key?("#{home_team.abbrev}_wins")
                teams["#{home_team.abbrev}_wins"] += 1
            else
                teams["#{home_team.abbrev}_wins"] = 1
            end
            
            if teams.has_key?("#{away_team.abbrev}_losses")
                teams["#{away_team.abbrev}_losses"] += 1
            else
                teams["#{away_team.abbrev}_losses"] = 1
            end
        end
    end

    # Starting goalie of the team based on goalie ratings
    def starting_goalie(goalies)
        # Get the goalie ratings
        goalie1 = Player.find_by(playerID: goalies[0].playerID)
        goalie2 = Player.find_by(playerID: goalies[1].playerID)
        goalie1_rating = goalie1.defensiveRating || 0
        goalie2_rating = goalie2.defensiveRating || 0

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
        return rand < 0.15
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

    # Which players got points on the goal
    def determine_goal_stats(line)
        player_ids = line.map(&:playerID)
        players = Player.where(playerID: player_ids)
        goal_scorer = nil
        assists = []

        # Get the first player to receive a point on the goal
        point_getter1 = select_point_getter(players)

        # 5% chance the goal was unassisted
        if rand < 0.05
            goal_scorer = point_getter1
        else
            # Get the second player to receive a point on the goal
            point_getter2 = select_point_getter(players - [point_getter1])
            
            # 30% chance the goal only has 1 assist
            if rand < 0.3
                # Find out which player scored the goal and which player assisted the goal
                point_getters = [point_getter1, point_getter2]
                goal_scorer = select_goal_scorer(point_getters)
                assists = point_getters - [goal_scorer]
            else
                # Get the third player to receive a point on the goal
                point_getter3 = select_point_getter(players - [point_getter1, point_getter2])
                
                # Find out which player scored the goal and which players assisted the goal
                point_getters = [point_getter1, point_getter2, point_getter3]
                goal_scorer = select_goal_scorer(point_getters)
                assists = point_getters - [goal_scorer]
            end
        end
        
        # Arrange the point getters by goal scorer first and then assists
        return [goal_scorer] + assists
    end

    # Selecting a player from the line to get the point based on offensive ratings
    def select_point_getter(players)
        # Normalize the ratings to have ratings show a greater effect on the point getters
        total_rating = players.sum { |player| player.offensiveRating**2 }
        normalized_ratings = players.map { |player| (player.offensiveRating**2).to_f / total_rating.to_f }
    
        selection_point = rand
        cumulative_rating = 0.0
    
        # Get a random decimal (0-1) and iterate through the normalized ratings until it reaches it to select the player 
        players.zip(normalized_ratings).each do |player, normalized_rating|
            cumulative_rating += normalized_rating
            return player if cumulative_rating >= selection_point
        end
    end

    # Selecting a player from the line to get the goal based on predicted goals stats
    def select_goal_scorer(players)
        # Get the predicted stats of the players
        player_ids = players.map(&:playerID)
        predicted_stats = SkaterStatsPrediction.where(playerID: player_ids)

        # Get the goal to point ratios of the players predicted stat to see who is more likely to score
        total_goal_to_point_ratios = predicted_stats.sum { |stat| stat.goals.to_f / (stat.points || 1) }
        goal_to_point_ratios = predicted_stats.map { |stat| (stat.goals.to_f / (stat.points || 1)) / total_goal_to_point_ratios }
    
        selection_point = rand
        cumulative_ratio = 0.0
        selected_stat = nil
        
        # Get a random decimal (0-1) and iterate through the ratios until it reaches it to select the player stat
        predicted_stats.zip(goal_to_point_ratios).each do |predicted_stat, goal_to_point_ratio|
            cumulative_ratio += goal_to_point_ratio
            if cumulative_ratio >= selection_point
                selected_stat = predicted_stat
                break
            end
        end
        
        # Get the player from the player stat
        player = Player.find_by(playerID: selected_stat.playerID)
        return player
    end
end