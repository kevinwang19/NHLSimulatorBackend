class GoalieStatsPredictionsController < ApplicationController
    # GET /goalie_stats_predictions/goalie_predicted_stats?playerID=:playerID
    def goalie_predicted_stats
        may_month = 5
        current_date = Time.now

        if current_date.month > may_month
            current_season = "#{current_date.year}#{current_date.year + 1}".to_i
        else
            current_season = "#{current_date.year - 1}#{current_date.year}".to_i
        end

        @stats_prediction = GoalieStatsPrediction.find_by(playerID: params[:playerID])
        if @stats_prediction
            serialized_stat = {
                playerID: @stats_prediction.playerID,
                season: current_season,
                gamesPlayed: @stats_prediction.gamesPlayed,
                gamesStarted: @stats_prediction.gamesStarted,
                wins: @stats_prediction.wins,
                losses: @stats_prediction.losses,
                otLosses: @stats_prediction.otLosses,
                goalsAgainst: @stats_prediction.goalsAgainst,
                goalsAgainstAvg: @stats_prediction.goalsAgainstAvg.to_f,
                savePctg: @stats_prediction.savePctg.to_f,
                shotsAgainst: @stats_prediction.shotsAgainst,
                shutouts: @stats_prediction.shutouts
            }
            render json: { goalieStats: [serialized_stat] }
        else
            render json: { error: "Goalie predicted stats not found" }, status: :not_found
        end
    end
end