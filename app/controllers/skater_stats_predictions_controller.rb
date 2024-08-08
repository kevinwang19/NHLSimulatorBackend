class SkaterStatsPredictionsController < ApplicationController
    # GET /skater_stats_predictions/skater_predicted_stats?playerID=:playerID
    def skater_predicted_stats
        may_month = 5
        seconds_in_minute = 60
        current_date = Time.now

        if current_date.month > may_month
            current_season = "#{current_date.year}#{current_date.year + 1}".to_i
        else
            current_season = "#{current_date.year - 1}#{current_date.year}".to_i
        end

        @stats_prediction = SkaterStatsPrediction.find_by(playerID: params[:playerID])
        if @stats_prediction
            total_toi_seconds = (@stats_prediction.avgToi * seconds_in_minute).round
            avg_toi_minutes = total_toi_seconds / seconds_in_minute
            avg_toi_seconds = total_toi_seconds % seconds_in_minute
            avg_toi = format("%d:%02d", avg_toi_minutes, avg_toi_seconds)

            serialized_stat = {
                playerID: @stats_prediction.playerID,
                season: current_season,
                gamesPlayed: @stats_prediction.gamesPlayed,
                goals: @stats_prediction.goals,
                assists: @stats_prediction.assists,
                points: @stats_prediction.points,
                avgToi: avg_toi,
                faceoffWinningPctg: @stats_prediction.faceoffWinningPctg.to_f,
                gameWinningGoals: @stats_prediction.gameWinningGoals,
                otGoals: @stats_prediction.otGoals,
                pim: @stats_prediction.pim,
                plusMinus: @stats_prediction.plusMinus,
                powerPlayGoals: @stats_prediction.powerPlayGoals,
                powerPlayPoints: @stats_prediction.powerPlayPoints,
                shootingPctg: @stats_prediction.shootingPctg.to_f,
                shorthandedGoals: @stats_prediction.shorthandedGoals,
                shorthandedPoints: @stats_prediction.shorthandedPoints,
                shots: @stats_prediction.shots
            }
            render json: { skaterStats: [serialized_stat] }
        else
            render json: { error: "Skater predicted stats not found" }, status: :not_found
        end
    end
end