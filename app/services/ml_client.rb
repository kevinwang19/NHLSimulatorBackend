require "open3"

class MlClient
    def initialize
        # Ensure the model is trained before making predictions
        script = "python3 app/services/ml/predict_stats.py train"
        stdout, stderr, status = Open3.capture3(script)
        unless status.success?
            raise "Training failed: #{stderr}"
        end
    end

    # Save prediction stats data to database
    def save_prediction_stats_data()
        # Iterate through all players in the database
        Player.all.each do |player|
            # Access the stats database and retrieve the most recent season stats for the specified player
            player_stats = player.positionCode == "G" ? GoalieStat.where(playerID: player.playerID) : SkaterStat.where(playerID: player.playerID)
            next if player_stats.empty?
            last_stats = player_stats.max_by { |row| row["season"] }

            # Stat columns to include
            include_columns = player.positionCode == "G" ?
            [
                :gamesPlayed, :gamesStarted, :wins, :losses, :otLosses,
                :goalsAgainst, :goalsAgainstAvg, :savePctg, :shotsAgainst, :shutouts
            ] :
            [
                :gamesPlayed, :goals, :assists, :points, :faceoffWinningPctg,
                :gameWinningGoals, :otGoals, :pim, :plusMinus, :powerPlayGoals,
                :powerPlayPoints, :shootingPctg, :shorthandedGoals, :shorthandedPoints, :shots
            ]

            stats = include_columns.map { |col| last_stats.send(col) }
            
            # Calculate player age at the beginning of each season
            birth_year = DateTime.parse(player.birthDate).year
            season_year = last_stats["season"].to_s[0..3].to_i
            age = season_year - birth_year

            # Call the predict function in the Python script
            script = "python3 app/services//ml/predict_stats.py predict #{player.positionCode} #{age} #{stats.join(" ")} "
            stdout, stderr, status = Open3.capture3(script)

            if status.success?
                # Get the prediction stats as an array
                prediction = stdout.strip.split(',').map(&:to_f)
                next if prediction.empty?
                    
                # Add goalie prediction stats to the GoalieStatPrediction table and skater prediction stats to the SkaterStatPrediction table
                if player.positionCode == "G"
                    goalie_prediction_stat = GoalieStatsPrediction.find_or_initialize_by(
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

                    goalie_prediction_stat.save
                else
                    skater_prediction_stat = SkaterStatsPrediction.find_or_initialize_by(
                        playerID: player.playerID,
                        gamesPlayed: prediction[0],
                        goals: prediction[1],
                        assists: prediction[2],
                        points: prediction[3],
                        faceoffWinningPctg: prediction[4],
                        gameWinningGoals: prediction[5],
                        otGoals: prediction[6],
                        pim: prediction[7],
                        plusMinus: prediction[8],
                        powerPlayGoals: prediction[9],
                        powerPlayPoints: prediction[10],
                        shootingPctg: prediction[11],
                        shorthandedGoals: prediction[12],
                        shorthandedPoints: prediction[13],
                        shots: prediction[14]
                    )
            
                    skater_prediction_stat.save
                end
            else
                puts "Error: #{stderr}"
            end
        end
    end
end