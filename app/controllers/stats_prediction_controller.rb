class StatsPredictionController < ApplicationController
    # GET /stats_prediction
    def index
        @stats_prediction = SkaterStatPrediction.all + GoalieStatPrediction.all
        render json: @stats_prediction
    end

    # GET /stats_prediction/:playerID
    def show
        @player = Player.find_by(playerID: params[:playerID])
        @stats_prediction = @player.position == "G" ? GoalieStatPrediction.find_by(playerID: params[:playerID]) : SkaterStatPrediction.find_by(playerID: params[:playerID])
        if @stats_prediction
            render json: @stats_prediction
        else
            render json: { error: "Stats prediction not found" }, status: :not_found
        end
    end
end