class LineupsController < ApplicationController
    # GET /lineups
    def index
        @lineups = Lineup.where.not(teamID: nil)
        render json: @lineups
    end

    # GET /lineups/:lineup_id
    def show
        @lineup = Lineup.find_by(lineupID: params[:lineup_id])
        if @lineup
            render json: @lineup
        else
            render json: { error: "Lineup not found" }, status: :not_found
        end
    end

    # GET /lineups/player_lineup:player_id
    def player_lineup
        @lineup = Lineup.find_by(playerID: params[:player_id])
        if @lineup
            render json: @lineup
        else
            render json: { error: "Player lineup not found" }, status: :not_found
        end
    end

    # GET /lineups/team_lineup/:team_id
    def team_lineup
        @lineups = Lineup.where(teamID: params[:team_id])
        if @lineups
            render json: @lineups
        else
            render json: { error: "Team lineup not found" }, status: :not_found
        end
    end
end