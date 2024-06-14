class RatingsGenerator
    # Save offensive and defensive ratings data to database
    def save_ratings_data(players, different_stats_player)
        # Weights of each stat for generating an accurate rating
        offensive_weights = {
            goals: 0.4,
            assists: 0.6,
            points: 0.8,
            avgToi: 0.05,
            game_winning_goals: 0.1,
            ot_goals: 0.3,
            powerplay_goals: 0.5,
            powerplay_points: 1.0,
            shots: 0.1
        }
        defensive_weights = {
            avgToi: 0.2,
            plus_minus: 1.0,
            shorthanded_goals: 2.0,
            shorthanded_points: 4.0,
            goals_against_avg: 0.2,
            shots_against: 0.03,
            shutouts: 3.0
        }
        goaltending_weights = {
            wins: 3.0,
            losses: 2.0,
            ot_losses: 1.5,
            goals_against_avg: 0.3,
            save_pctg: 1.2,
            shutouts: 2.0,
            games_played: 0.06
        }

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
        
        # Get ratings for each player
        players.each do |player|
            # If the players stats and prediction stats have not changed, keep the existing ratings
            next unless different_stats_player.include?(player.playerID)

            if player.positionCode == "G"
                goalie_rating = 0

                # Find the predicted stat of the matching player
                player_stats = GoalieStatsPrediction.find_by(playerID: player.playerID)
                
                # Calculate rating based on the stats and weight if player's stats exist
                if player_stats
                    goalie_rating += ((player_stats.wins.to_f / player_stats.gamesPlayed) * goaltending_weights[:wins])
                    goalie_rating -= ((player_stats.losses.to_f / player_stats.gamesPlayed) * goaltending_weights[:losses])
                    goalie_rating += ((player_stats.otLosses.to_f / player_stats.gamesPlayed) * goaltending_weights[:ot_losses])
                    goalie_rating -= (player_stats.goalsAgainstAvg * goaltending_weights[:goals_against_avg])
                    goalie_rating += (player_stats.savePctg * goaltending_weights[:save_pctg])
                    goalie_rating += ((player_stats.shutouts.to_f / player_stats.gamesPlayed) * goaltending_weights[:shutouts])
                    goalie_rating += (player_stats.gamesPlayed.to_f * goaltending_weights[:games_played])
                    goalie_rating = ((goalie_rating * 10) + 35).round
                end

                # Insert the rating value into the database for the matching player
                player = Player.find_by(playerID: player.playerID)
                player.defensiveRating = goalie_rating

                player.save
            else
                offensive_rating = 0
                defensive_rating = 0

                # Find the predicted stat of the matching player
                player_stats = SkaterStatsPrediction.find_by(playerID: player.playerID)
 
                # Calculate rating based on the stats and weight if player's stats exist
                if player_stats
                    offensive_rating += ((player_stats.goals.to_f / player_stats.gamesPlayed) * offensive_weights[:goals])
                    offensive_rating += ((player_stats.assists.to_f / player_stats.gamesPlayed) * offensive_weights[:assists])
                    offensive_rating += ((player_stats.points.to_f / player_stats.gamesPlayed) * offensive_weights[:points])
                    offensive_rating += (player_stats.avgToi * offensive_weights[:avgToi])
                    offensive_rating += ((player_stats.gameWinningGoals.to_f / player_stats.gamesPlayed) * offensive_weights[:game_winning_goals])
                    offensive_rating += ((player_stats.otGoals.to_f / player_stats.gamesPlayed) * offensive_weights[:ot_goals])
                    offensive_rating += ((player_stats.powerPlayGoals.to_f / player_stats.gamesPlayed) * offensive_weights[:powerplay_goals])
                    offensive_rating += ((player_stats.powerPlayPoints.to_f / player_stats.gamesPlayed) * offensive_weights[:powerplay_points])
                    offensive_rating += ((player_stats.shots.to_f / player_stats.gamesPlayed) * offensive_weights[:shots])
                    offensive_rating += (player.positionCode != "D" ? 2.5 : 2.0)
                    offensive_rating = ((offensive_rating * 10) + 25).round

                    defensive_rating += (player_stats.avgToi * defensive_weights[:avgToi])
                    defensive_rating += ((player_stats.plusMinus.to_f / player_stats.gamesPlayed) * defensive_weights[:plus_minus])
                    defensive_rating += ((player_stats.plusMinus.to_f / player_stats.gamesPlayed) * defensive_weights[:plus_minus])
                    defensive_rating += ((player_stats.shorthandedGoals.to_f / player_stats.gamesPlayed) * defensive_weights[:shorthanded_goals])
                    defensive_rating += ((player_stats.shorthandedPoints.to_f / player_stats.gamesPlayed) * defensive_weights[:shorthanded_points])
                    defensive_rating -= ((goals_against_avg_sum.to_f / num_goalies) * defensive_weights[:goals_against_avg])
                    defensive_rating -= ((shots_against_per_game_sum.to_f / num_goalies) * defensive_weights[:shots_against])
                    defensive_rating += ((shutouts_per_game_sum.to_f / num_goalies) * defensive_weights[:shutouts])
                    defensive_rating += (player.positionCode == "D" ? 2.5 : (player.positionCode == "C" ? 2.0 : 1.5))
                    defensive_rating = ((defensive_rating * 10) + 15).round
                end

                # Insert the rating value into the database for the matching player
                player = Player.find_by(playerID: player.playerID)
                player.offensiveRating = offensive_rating
                player.defensiveRating = defensive_rating
 
                player.save
            end
        end
    end
end