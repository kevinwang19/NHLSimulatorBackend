require_relative "../../../config/constants"
require "open3"

module Ml
    class MlClient
        def initialize
            # Ensure the model is trained before making predictions
            script = "python3 app/services/ml/predict_stats.py train"
            stdout, stderr, status = Open3.capture3(script)
            unless status.success?
                raise "Training failed: #{stderr}"
            end
        end
        
        # Convert "mm:ss" time to a decimal
        def time_to_decimal(time_str)
            return 0.0 unless time_str.is_a?(String) && time_str.match?(/^\d{1,2}:\d{2}$/)
            minutes, seconds = time_str.split(':').map(&:to_i)
            return minutes + (seconds / 60.0)
        end

        # Store column results to an array
        def stats_to_array(columns, stats)
            stats_array = columns.map do |col| 
                value = stats.send(col)

                # Check if the value is a time string and convert it to decimal if so
                if value.is_a?(String) && value.match?(/^\d{1,2}:\d{2}$/)
                    time_to_decimal(value)
                else
                    value
                end
            end

            return stats_array
        end

        # Combine stats for the same season
        def combine_stats(season_desc_stats)
            combined_stats = []
            averaging_stats = ["faceoffWinningPctg", "shootingPctg", "goalsAgainstAvg", "savePctg"]
    
            season_desc_stats.each do |row|
                # Find matching season rows
                existing_entry = combined_stats.find { |entry| entry.season == row.season }
    
                if existing_entry
                    row.attributes.each do |key, value|
                        next if key == "season"
            
                        # Calculate average of avgToi
                        if key == "avgToi"
                            existing_entry["avgToi"] = (time_to_decimal(existing_entry[key]) + time_to_decimal(value)) / 2.0
                        # Calculate average for averaging stats
                        elsif averaging_stats.include?(key)
                            existing_entry[key] = ((existing_entry[key] || 0) + (value || 0)) / 2.0
                        elsif value.is_a?(Numeric)
                            # Sum numeric values
                            existing_entry[key] = (existing_entry[key] || 0) + (value || 0)
                        end
                    end
                else
                    combined_stats << row.dup
                end
            end
    
            return combined_stats
        end

        # Save prediction stats data to database
        def save_prediction_stats_data(different_stats_player, recent_season)
            # Iterate through all players in the database
            Player.all.each do |player|
                # If the players stats have not changed, keep the existing predictions
                next unless different_stats_player.include?(player.playerID)

                # Access the stats database and retrieve the most recent season stats for the specified player
                player_stats = player.positionCode == "G" ? GoalieStat.where(playerID: player.playerID) : SkaterStat.where(playerID: player.playerID)
                next if player_stats.empty?

                # Sort player_stats by season in descending order
                season_desc_stats = player_stats.sort_by { |row| -row.season }

                # Combine stats for the same season
                combined_stats = combine_stats(season_desc_stats)

                # Find the first row with gamesPlayed > 10 for non-goalies, otherwise take the first row
                if player.positionCode == "G"
                    last_valid_stats = combined_stats.first
                else
                    last_valid_stats = combined_stats.find { |row| row.gamesPlayed > VALID_STATS_MIN_GAMES }
                    
                    # If no valid row is found, return the row with the highest season
                    last_valid_stats ||= combined_stats.first
                end

                # Get the second most recent season stats
                second_last_valid_stats = combined_stats.find { |row| row.season == last_valid_stats.season - 1 }

                # Stat columns to include
                include_columns = player.positionCode == "G" ?
                [
                    :gamesPlayed, :gamesStarted, :wins, :losses, :otLosses,
                    :goalsAgainst, :goalsAgainstAvg, :savePctg, :shotsAgainst, :shutouts
                ] :
                [
                    :gamesPlayed, :goals, :assists, :points, :avgToi, :faceoffWinningPctg,
                    :gameWinningGoals, :otGoals, :pim, :plusMinus, :powerPlayGoals,
                    :powerPlayPoints, :shootingPctg, :shorthandedGoals, :shorthandedPoints, :shots
                ]

                # Array of most recent stats
                stats = stats_to_array(include_columns, last_valid_stats)
                
                # Array of second-most recent stats
                prev_stats = nil
                if second_last_valid_stats
                    prev_stats = stats_to_array(include_columns, second_last_valid_stats)
                end
                
                # Calculate player age at the beginning of each season
                birth_year = DateTime.parse(player.birthDate).year
                season_year = combined_stats.first.season.to_s[0..3].to_i
                age = season_year - birth_year

                # Make stats invalid if there are no stats from the most recent season
                next if combined_stats.first.season < recent_season

                # Call the predict function in the Python script
                if prev_stats.nil?
                    script = "python3 app/services/ml/predict_stats.py predict #{player.positionCode} #{age} #{stats.join(" ")}"
                else
                    script = "python3 app/services/ml/predict_stats.py predict #{player.positionCode} #{age} #{stats.join(" ")} #{prev_stats.join(" ")}"
                end

                stdout, stderr, status = Open3.capture3(script)

                if status.success?
                    # Get the prediction stats as an array
                    prediction = stdout.strip.split(',').map(&:to_f)
                    next if prediction.empty?

                    # Add goalie prediction stats to the GoalieStatPrediction table and skater prediction stats to the SkaterStatPrediction table
                    if player.positionCode == "G"
                        # Find if the goalie prediction stats already exists in the database
                        existing_goalie_prediction = GoalieStatsPrediction.find_by(playerID: player.playerID)
                        
                        # Update prediction stats if the record exists, otherwise add a new prediction record to the database
                        if existing_goalie_prediction
                            existing_goalie_prediction.update(
                                gamesPlayed: prediction[0],
                                gamesStarted: prediction[1],
                                wins: prediction[2],
                                losses: prediction[3],
                                otLosses: prediction[4],
                                goalsAgainst: prediction[5],
                                goalsAgainstAvg: prediction[6],
                                savePctg: prediction[7],
                                shotsAgainst: prediction[8],
                                shutouts: prediction[9]
                            )
                        else
                            GoalieStatsPrediction.create(
                            playerID: player.playerID,
                            gamesPlayed: prediction[0],
                            gamesStarted: prediction[1],
                            wins: prediction[2],
                            losses: prediction[3],
                            otLosses: prediction[4],
                            goalsAgainst: prediction[5],
                            goalsAgainstAvg: prediction[6],
                            savePctg: prediction[7],
                            shotsAgainst: prediction[8],
                            shutouts: prediction[9]
                        )
                        end
                    else
                        # Find if the skater prediction stats already exists in the database
                        existing_skater_prediction = SkaterStatsPrediction.find_by(playerID: player.playerID)
                        
                        # Update prediction stats if the record exists, otherwise add a new prediction record to the database
                        if existing_skater_prediction
                            existing_skater_prediction.update(
                                gamesPlayed: prediction[0],
                                goals: prediction[1],
                                assists: prediction[2],
                                points: prediction[3],
                                avgToi: prediction[4],
                                faceoffWinningPctg: prediction[5],
                                gameWinningGoals: prediction[6],
                                otGoals: prediction[7],
                                pim: prediction[8],
                                plusMinus: prediction[9],
                                powerPlayGoals: prediction[10],
                                powerPlayPoints: prediction[11],
                                shootingPctg: prediction[12],
                                shorthandedGoals: prediction[13],
                                shorthandedPoints: prediction[14],
                                shots: prediction[15]
                            )
                        else
                            SkaterStatsPrediction.create(
                                playerID: player.playerID,
                                gamesPlayed: prediction[0],
                                goals: prediction[1],
                                assists: prediction[2],
                                points: prediction[3],
                                avgToi: prediction[4],
                                faceoffWinningPctg: prediction[5],
                                gameWinningGoals: prediction[6],
                                otGoals: prediction[7],
                                pim: prediction[8],
                                plusMinus: prediction[9],
                                powerPlayGoals: prediction[10],
                                powerPlayPoints: prediction[11],
                                shootingPctg: prediction[12],
                                shorthandedGoals: prediction[13],
                                shorthandedPoints: prediction[14],
                                shots: prediction[15]
                            )
                        end
                    end
                else
                    puts "Error: #{stderr}"
                end
            end
        end
    end
end