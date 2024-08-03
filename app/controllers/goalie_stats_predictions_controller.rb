class GoalieStatsPredictionsController < ApplicationController
    # GET /goalie_stats_predictions
    def index
        @stats_predictions = GoalieStatsPrediction.all
        render json: { goalie_stats_predictions: @stats_predictions }
    end

    # GET /goalie_stats_predictions/:playerID
    def show
        @stats_prediction = GoalieStatsPrediction.find_by(playerID: params[:playerID])
        if @stats_prediction
            render json: { goalie_stats_predictions: @stats_prediction }
        else
            render json: { error: "Goalie stat prediction not found" }, status: :not_found
        end
    end
end