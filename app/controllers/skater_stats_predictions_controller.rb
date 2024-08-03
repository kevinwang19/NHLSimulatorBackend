class SkaterStatsPredictionsController < ApplicationController
    # GET /skater_stats_predictions
    def index
        @stats_predictions = SkaterStatsPrediction.all
        render json: { skater_stats_predictions: @stats_predictions }
    end

    # GET /skater_stats_predictions/:playerID
    def show
        @stats_prediction = SkaterStatsPrediction.find_by(playerID: params[:playerID])
        if @stats_prediction
            render json: { skater_stats_predictions: @stats_prediction }
        else
            render json: { error: "Skater stat prediction not found" }, status: :not_found
        end
    end
end