class StatsController < ApplicationController
    # GET /stats
    def index
        @stats = SkaterStat.all + GoalieStat.all
        render json: @stats
    end

    # GET /stats/:playerID
    def show
        @player = Player.find_by(playerID: params[:playerID])
        @stats = @player.position == "G" ? GoalieStat.where(playerID: params[:playerID]) : SkaterStat.where(playerID: params[:playerID])
        if @stats
            render json: @stats
        else
            render json: { error: "Stats not found" }, status: :not_found
        end
    end
end