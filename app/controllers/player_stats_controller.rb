class PlayerStatsController < ApplicationController
    # GET /player_stats
    def index
        @stats = SkaterStat.all + GoalieStat.all
        render json: @stats
    end

    # GET /player_stats/:position_code/:stat_id
    def show
        @stat = params[:position_code] == "G" ? 
            GoalieStat.find_by(goalieStatID: params[:stat_id]) : 
            SkaterStat.find_by(skaterStatID: params[:stat_id])
        if @stat
            render json: @stat
        else
            render json: { error: "Player stat not found" }, status: :not_found
        end
    end

    # GET /player_stats/player_season_stats/:player_id/:season
    def player_season_stats
        @player = Player.find_by(playerID: params[:player_id])
        @stat = @player.positionCode == "G" ? 
            GoalieStat.where(playerID: params[:player_id], season: params[:season]) : 
            SkaterStat.where(playerID: params[:player_id], season: params[:season])
        if @stat
            render json: @stat
        else
            render json: { error: "Player season stats not found" }, status: :not_found
        end
    end

    # GET /player_stats/player_career_stats/:player_id
    def player_career_stats
        @player = Player.find_by(playerID: params[:player_id])
        @stats = @player.positionCode == "G" ? 
            GoalieStat.where(playerID: params[:player_id]) : 
            SkaterStat.where(playerID: params[:player_id])
        if @stats
            render json: @stats
        else
            render json: { error: "Player career stats not found" }, status: :not_found
        end
    end
end