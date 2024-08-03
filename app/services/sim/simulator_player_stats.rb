module Sim
    class SimulatorPlayerStats
        def simulate_skater_stats(simulation_id, team_line, is_powerplay)
            # Determine who scored the goal and got the assists
            scoring_log = determine_scoring_log(team_line)

            # Save stats to database, first element is a goal, other elements are assists
            scoring_log.each_with_index do |skater, index|
                if index == 0
                    save_simulation_skater_stats_goal(simulation_id, skater, is_powerplay)
                else
                    save_simulation_skater_stats_assist(simulation_id, skater, is_powerplay)
                end
            end
        end

        # Which players got points on the goal
        def determine_scoring_log(line)
            player_ids = line.map(&:playerID)
            players = Player.where(playerID: player_ids)
            goal_scorer = nil
            assists = []

            # Get the first player to receive a point on the goal
            point_getter1 = select_point_getter(players)

            # 5% chance the goal was unassisted
            if rand < UNASSITED_GOAL_PERCENTAGE
                goal_scorer = point_getter1
            else
                # Get the second player to receive a point on the goal
                point_getter2 = select_point_getter(players - [point_getter1])
                
                # 30% chance the goal only has 1 assist
                if rand < SINGLE_ASSISTED_GOAL_PERCENTAGE
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

        # Save new games played simulated player stats to database
        def save_simulation_player_stats_initial(simulation_id, players)
            # Get each player that is playing
            players.each do |player|
                # Save goalie stats to SimulationGoalieStat and skater stats to SimulationSkaterStat
                if player.position == "G"
                    # Find the current simulation goalie stats from the database
                    goalie_stat = SimulationGoalieStat.find_by(simulationID: simulation_id, playerID: player.playerID)

                    # Update games played stat since the record exists from the simulation initiation
                    if goalie_stat
                        goalie_stat.update(gamesPlayed: goalie_stat.gamesPlayed + 1)
                    end
                else
                    # Find the current simulation skater stats from the database
                    skater_stat = SimulationSkaterStat.find_by(simulationID: simulation_id, playerID: player.playerID)

                    # Update games played stat since the record exists from the simulation initiation
                    if skater_stat
                        skater_stat.update(gamesPlayed: skater_stat.gamesPlayed + 1)
                    end
                end
            end
        end

        # Save goal scorer simulated stats to SimulationSkaterStats database
        def save_simulation_skater_stats_goal(simulation_id, skater, is_powerplay)
            # Find the current simulation skater stats from the database
            skater_stat = SimulationSkaterStat.find_by(simulationID: simulation_id, playerID: skater.playerID)

            # Update goal stats since the record exists from the simulation initiation
            if skater_stat
                skater_stat.update(
                    goals: skater_stat.goals + 1,
                    points: skater_stat.points + 1,
                    powerPlayGoals: is_powerplay ? skater_stat.powerPlayGoals + 1 : skater_stat.powerPlayGoals,
                    powerPlayPoints: is_powerplay ? skater_stat.powerPlayPoints + 1 : skater_stat.powerPlayPoints
                )
            end
        end

        # Save assist simulated stats to SimulationSkaterStats database
        def save_simulation_skater_stats_assist(simulation_id, skater, is_powerplay)
            # Find the current simulation skater stats from the database
            skater_stat = SimulationSkaterStat.find_by(simulationID: simulation_id, playerID: skater.playerID)

            # Update assist stats since the record exists from the simulation initiation
            if skater_stat
                skater_stat.update(
                    assists: skater_stat.assists + 1,
                    points: skater_stat.points + 1,
                    powerPlayPoints: is_powerplay ? skater_stat.powerPlayPoints + 1 : skater_stat.powerPlayPoints
                )
            end
        end

        # Save winning goalie simulated stats to SimulationGoalieStats database
        def save_simulation_goalie_stats_win(simulation_id, goalie, goals_allowed)
            # Find the current simulation goalie stats from the database
            goalie_stat = SimulationGoalieStat.find_by(simulationID: simulation_id, playerID: goalie.playerID)

            # Find out the total goals allowed before the current game and add the new amount of goals allowed to calculate the new average
            total_goals_allowed = goalie_stat.goalsAgainstPerGame * (goalie_stat.gamesPlayed - 1)
            total_goals_allowed += goals_allowed
            new_goals_against_per_game = total_goals_allowed / goalie_stat.gamesPlayed.to_f

            # Update win and goalie stats since the record exists from the simulation initiation
            if goalie_stat
                goalie_stat.update(
                    wins: goalie_stat.wins + 1,
                    goalsAgainstPerGame: new_goals_against_per_game,
                    shutouts: goals_allowed == 0 ? goalie_stat.shutouts + 1 : goalie_stat.shutouts
                )
            end
        end

        # Save losing goalie simulated stats to SimulationGoalieStats database
        def save_simulation_goalie_stats_loss(simulation_id, goalie, goals_allowed, required_ot)
            # Find the current simulation goalie stats from the database
            goalie_stat = SimulationGoalieStat.find_by(simulationID: simulation_id, playerID: goalie.playerID)

            # Find out the total goals allowed before the current game and add the new amount of goals allowed to calculate the new average
            total_goals_allowed = goalie_stat.goalsAgainstPerGame * (goalie_stat.gamesPlayed - 1)
            total_goals_allowed += goals_allowed
            new_goals_against_per_game = total_goals_allowed / goalie_stat.gamesPlayed.to_f

            # Update loss and goalie stats since the record exists from the simulation initiation
            if goalie_stat
                goalie_stat.update(
                    losses: required_ot ? goalie_stat.losses : goalie_stat.losses + 1,
                    otLosses: required_ot ? goalie_stat.otLosses + 1 : goalie_stat.otLosses,
                    goalsAgainstPerGame: new_goals_against_per_game,
                    shutouts: goals_allowed == 0 ? goalie_stat.shutouts + 1 : goalie_stat.shutouts
                )
            end
        end
    end
end