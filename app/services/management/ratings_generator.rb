require_relative "../../config/constants"

class RatingsGenerator
    # Save initial offensive and defensive ratings data to database at the start of the season
    def save_initial_ratings_data(players, different_stats_player)
        goals_against_avg_sum = 0
        shots_against_per_game_sum = 0
        shutouts_per_game_sum = 0
        num_goalies = 0

        # Record some collective goalie stats to use for player defensive stats
        goalies = players.select { |player| player.positionCode == "G" }
        goalies.each do |goalie|
            # Find the predicted stat of the matching goalie
            goalie_stats = GoalieStatsPrediction.find_by(playerID: goalie.playerID)
            
            # Calculate cumulative goalie stats
            if goalie_stats
                goals_against_avg_sum += goalie_stats.goalsAgainstAvg
                shots_against_per_game_sum += (goalie_stats.shotsAgainst / goalie_stats.gamesPlayed)
                shutouts_per_game_sum += (goalie_stats.shutouts / goalie_stats.gamesPlayed)
                num_goalies += 1
            end
        end

        # Calculate team defense stats based on collective goalie stats
        team_goals_against_avg = goals_against_avg_sum.to_f / num_goalies
        team_shots_against_per_game = shots_against_per_game_sum.to_f / num_goalies
        team_shutouts_per_game = shutouts_per_game_sum.to_f / num_goalies
        
        # Get ratings for each player
        players.each do |player|
            # If the players stats and prediction stats have not changed, keep the existing ratings
            next unless different_stats_player.include?(player.playerID)

            if player.positionCode == "G"
                # Find the predicted stats of the matching goalie
                goalie_stats = GoalieStatsPrediction.find_by(playerID: player.playerID)
                
                # Goalie rating based on the predicted stats of the goalie
                goalie_rating = calculate_goalie_rating(goalie_stats, NUM_GAMES_IN_SEASON)

                # Insert the rating value into the database for the matching goalie
                goalie = Player.find_by(playerID: player.playerID)
                goalie.defensiveRating = goalie_rating

                goalie.save
            else
                # Find the predicted stats of the matching skater
                skater_stats = SkaterStatsPrediction.find_by(playerID: player.playerID)
 
                # Skater rating based on the predicted stats of the skater
                offensive_rating, defensive_rating = calculate_skater_ratings(
                    skater_stats, 
                    player.positionCode, 
                    team_goals_against_avg, 
                    team_shots_against_per_game, 
                    team_shutouts_per_game
                )

                # Insert the rating value into the database for the matching skater
                skater = Player.find_by(playerID: player.playerID)
                skater.offensiveRating = offensive_rating
                skater.defensiveRating = defensive_rating
 
                skater.save
            end
        end
    end

    # Save updated offensive and defensive ratings data to database at season updates
    def save_updated_ratings_data(players, season, different_stats_player)
        goals_against_avg_sum = 0
        shots_against_per_game_sum = 0
        shutouts_per_game_sum = 0
        num_goalies = 0

        # Record new season collective goalie stats to use for player defensive stats
        goalies = players.select { |player| player.positionCode == "G" }
        goalies.each do |goalie|
            # Find the stats of the matching goalie from the current season
            goalie_stats = GoalieStat.find_by(playerID: goalie.playerID, season: season)
            
            # Calculate cumulative goalie stats
            if goalie_stats
                goals_against_avg_sum += goalie_stats.goalsAgainstAvg
                shots_against_per_game_sum += (goalie_stats.shotsAgainst / goalie_stats.gamesPlayed)
                shutouts_per_game_sum += (goalie_stats.shutouts / goalie_stats.gamesPlayed)
                num_goalies += 1
            end
        end
        
        # Get the amount of games played so far in the current season
        current_games_played = SkaterStat.maximum(:gamesPlayed)

        # Calculate team defense stats based on collective goalie stats
        team_goals_against_avg = goals_against_avg_sum.to_f / num_goalies
        team_shots_against_per_game = shots_against_per_game_sum.to_f / num_goalies
        team_shutouts_per_game = shutouts_per_game_sum.to_f / num_goalies

        # Get updated ratings for each player
        players.each do |player|
            # If the players stats and prediction stats have not changed, keep the existing ratings
            next unless different_stats_player.include?(player.playerID)

            if player.positionCode == "G"
                # Find the current stats of the matching goalie
                goalie_stats = GoalieStat.find_by(playerID: player.playerID, season: season)

                # New goalie rating based on the new stats of the goalie
                new_goalie_rating = calculate_goalie_rating(goalie_stats, current_games_played)

                # Insert the rating value into the database for the matching skater
                goalie = Player.find_by(playerID: player.playerID)

                # If the goalie already has a rating, update it with the average of the old and new rating, otherwise use the new rating
                if goalie.defensiveRating
                    old_goalie_rating = goalie.defensiveRating
                    updated_goalie_rating = ((new_goalie_rating + old_goalie_rating) / 2.0).round
                    goalie.defensiveRating = updated_goalie_rating
                else
                    goalie.defensiveRating = new_goalie_rating
                end

                goalie.save
            else
                # Find the current stat of the matching skater
                skater_stats = SkaterStat.find_by(playerID: player.playerID, season: season)
 
                # New skater rating based on the new stats of the skater
                new_offensive_rating, new_defensive_rating  = calculate_skater_ratings(
                    skater_stats, 
                    player.positionCode, 
                    team_goals_against_avg, 
                    team_shots_against_per_game, 
                    team_shutouts_per_game
                )

                # Insert the rating value into the database for the matching skater
                skater = Player.find_by(playerID: player.playerID)

                # If the goalie already has offensive and defensive rating, update it with the average of the old and new ratings, otherwise use the new ratings
                if skater.offensiveRating
                    old_offensive_rating = skater.offensiveRating
                    updated_offensive_rating = ((new_offensive_rating + old_offensive_rating) / 2.0).round
                    skater.offensiveRating = updated_offensive_rating
                else
                    skater.offensiveRating = new_offensive_rating
                end

                if skater.defensiveRating
                    old_defensive_rating = skater.defensiveRating
                    updated_defensive_rating = ((new_defensive_rating + old_defensive_rating) / 2.0).round
                    skater.defensiveRating = updated_defensive_rating
                else
                    skater.defensiveRating = new_defensive_rating
                end
 
                skater.save
            end
        end
    end

    # Calculate goalie rating based on the stats and weight if the goalie's stats exist
    def calculate_goalie_rating(goalie_stats, season_games)
        # Weights of each goalie stat for generating an accurate goalie rating
        goaltending_weights = {
            wins: 3.0,
            losses: 2.0,
            ot_losses: 1.5,
            goals_against_avg: 1.0,
            save_pctg: 2.5,
            shutouts: 2.0,
            games_played: 5
        }
        goalie_rating = 0
        
        if goalie_stats
            goalie_rating += ((goalie_stats.wins.to_f / goalie_stats.gamesPlayed) * goaltending_weights[:wins])
            goalie_rating -= ((goalie_stats.losses.to_f / goalie_stats.gamesPlayed) * goaltending_weights[:losses])
            goalie_rating += ((goalie_stats.otLosses.to_f / goalie_stats.gamesPlayed) * goaltending_weights[:ot_losses])
            goalie_rating -= (goalie_stats.goalsAgainstAvg * goaltending_weights[:goals_against_avg])
            goalie_rating += (goalie_stats.savePctg * goaltending_weights[:save_pctg])
            goalie_rating += ((goalie_stats.shutouts.to_f / goalie_stats.gamesPlayed) * goaltending_weights[:shutouts])
            goalie_rating += ((goalie_stats.gamesPlayed.to_f / season_games) * goaltending_weights[:games_played])
            goalie_rating = ((goalie_rating * 10) + 50).round
        end

        return goalie_rating
    end

    # Calculate skater offensive and defensive ratings based on the stats and weight if the skaters's stats exist
    def calculate_skater_ratings(skater_stats, player_position, team_goals_against_avg, team_shots_against_per_game, team_shutouts_per_game)
        # Weights of each skater stat for generating an accurate offensive and defensive rating
        offensive_weights = {
            goals: 0.6,
            assists: 0.7,
            points: 0.8,
            fwdAvgToi: 0.05,
            defAvgToi: 0.03,
            game_winning_goals: 0.2,
            ot_goals: 0.3,
            powerplay_goals: 0.8,
            powerplay_points: 1.0,
            shots: 0.1
        }
        defensive_weights = {
            avgToi: 0.2,
            plus_minus: 0.7,
            faceoff_winning_pctg: 4.0,
            shorthanded_goals: 1.0,
            shorthanded_points: 1.5,
            goals_against_avg: 0.2,
            shots_against: 0.03,
            shutouts: 3.0
        }
        offensive_rating = 0
        defensive_rating = 0

        if skater_stats
            offensive_rating += ((skater_stats.goals.to_f / skater_stats.gamesPlayed) * offensive_weights[:goals])
            offensive_rating += ((skater_stats.assists.to_f / skater_stats.gamesPlayed) * offensive_weights[:assists])
            offensive_rating += ((skater_stats.points.to_f / skater_stats.gamesPlayed) * offensive_weights[:points])
            offensive_rating += (player_position != "D" ? skater_stats.avgToi * offensive_weights[:fwdAvgToi] : skater_stats.avgToi * offensive_weights[:defAvgToi])
            offensive_rating += ((skater_stats.gameWinningGoals.to_f / skater_stats.gamesPlayed) * offensive_weights[:game_winning_goals])
            offensive_rating += ((skater_stats.otGoals.to_f / skater_stats.gamesPlayed) * offensive_weights[:ot_goals])
            offensive_rating += ((skater_stats.powerPlayGoals.to_f / skater_stats.gamesPlayed) * offensive_weights[:powerplay_goals])
            offensive_rating += ((skater_stats.powerPlayPoints.to_f / skater_stats.gamesPlayed) * offensive_weights[:powerplay_points])
            offensive_rating += ((skater_stats.shots.to_f / skater_stats.gamesPlayed) * offensive_weights[:shots])
            offensive_rating = ((offensive_rating * 10) + 50).round

            defensive_rating += (skater_stats.avgToi * defensive_weights[:avgToi])
            defensive_rating += ((skater_stats.plusMinus.to_f / skater_stats.gamesPlayed) * defensive_weights[:plus_minus])
            defensive_rating += ((skater_stats.plusMinus.to_f / skater_stats.gamesPlayed) * defensive_weights[:plus_minus])
            defensive_rating += ((skater_stats.shorthandedGoals.to_f / skater_stats.gamesPlayed) * defensive_weights[:shorthanded_goals])
            defensive_rating += ((skater_stats.shorthandedPoints.to_f / skater_stats.gamesPlayed) * defensive_weights[:shorthanded_points])
            defensive_rating -= (team_goals_against_avg * defensive_weights[:goals_against_avg])
            defensive_rating -= (team_shots_against_per_game * defensive_weights[:shots_against])
            defensive_rating += (team_shutouts_per_game * defensive_weights[:shutouts])
            defensive_rating += (player_position == "D" ? 3.0 : 0.0)
            defensive_rating += (player_position == "C" ? (skater_stats.faceoffWinningPctg * defensive_weights[:faceoff_winning_pctg]) : 0.0)
            defensive_rating += ((player_position == "L" || player_position == "R") ? 1.5 : 0)
            defensive_rating = ((defensive_rating * 10) + 20).round
        end

        return [offensiveRating, defensiveRating]
    end
end