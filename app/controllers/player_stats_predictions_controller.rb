class PlayerStatsPredictionsController < ApplicationController
    # GET /player_stats_predictions
    def index
        @stats_predictions = SkaterStatPrediction.all + GoalieStatPrediction.all
        render json: @stats_predictions
    end

    # GET /player_stats_predictions/:position_code/:predicted_stat_id
    def show
        @stats_prediction = params[:position_code] == "G" ? 
            GoalieStatPrediction.find_by(goaliePredictedStatID: params[:predicted_stat_id]) : 
            SkaterStatPrediction.find_by(skaterPredictedStatID: params[:predicted_stat_id])
        if @stats_prediction
            render json: @stats_prediction
        else
            render json: { error: "Stat prediction not found" }, status: :not_found
        end
    end

    # GET /player_stats_predictions/player_predicted_stats:player_id
    def player_predicted_stats
        @player = Player.find_by(playerID: params[:player_id])
        @stats_prediction = @player.position == "G" ? 
            GoalieStatPrediction.find_by(playerID: params[:player_id]) : 
            SkaterStatPrediction.find_by(playerID: params[:player_id])
        if @stats_prediction
            render json: @stats_prediction
        else
            render json: { error: "Player stats prediction not found" }, status: :not_found
        end
    end
end