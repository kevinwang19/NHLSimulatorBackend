class SkaterStatsController < ApplicationController
    # GET /skater_stats
    def index
        @stats = SkaterStat.all
        render json: { skater_stats: @stats }
    end

    # GET /skater_stats/:statID
    def show
        @stat = SkaterStat.find_by(skaterStatID: params[:statID])
        if @stat
            render json: { skater_stats: @stat }
        else
            render json: { error: "Skater stat not found" }, status: :not_found
        end
    end

    # GET /skater_stats/skater_season_stats/:playerID/:season
    def skater_season_stats
        @stat = SkaterStat.where(playerID: params[:playerID], season: params[:season])
        if @stat
            render json: { skater_stats: @stat }
        else
            render json: { error: "Skater season stats not found" }, status: :not_found
        end
    end

    # GET /skater_stats/skater_career_stats/:playerID
    def skater_career_stats
        @stats = SkaterStat.where(playerID: params[:playerID])
        if @stats
            render json: { skater_stats: @stats }
        else
            render json: { error: "Skater career stats not found" }, status: :not_found
        end
    end
end