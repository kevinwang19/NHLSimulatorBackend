class GoalieStatsController < ApplicationController
    # GET /goalie_stats
    def index
        @stats = GoalieStat.all
        render json: { goalie_stats: @stats }
    end

    # GET /goalie_stats/:statID
    def show
        @stat = GoalieStat.find_by(goalieStatID: params[:statID])
        if @stat
            render json: { goalie_stats: @stat }
        else
            render json: { error: "Goalie stat not found" }, status: :not_found
        end
    end

    # GET /goalie_stats/goalie_season_stats/:playerID/:season
    def goalie_season_stats
        @stat = GoalieStat.where(playerID: params[:playerID], season: params[:season])
        if @stat
            render json: { goalie_stats: @stat }
        else
            render json: { error: "Goalie season stats not found" }, status: :not_found
        end
    end

    # GET /goalie_stats/goalie_career_stats/:playerID
    def goalie_career_stats
        @stats = GoalieStat.where(playerID: params[:playerID])
        if @stats
            render json: { goalie_stats: @stats }
        else
            render json: { error: "Goalie career stats not found" }, status: :not_found
        end
    end
end