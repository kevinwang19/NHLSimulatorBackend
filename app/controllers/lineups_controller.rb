class LineupsController < ApplicationController
    # GET /lineups
    def index
        @lineups = Lineup.where.not(teamID: nil)
        render json: { lineups: @lineups }
    end

    # GET /lineups/:lineupID
    def show
        @lineup = Lineup.find_by(lineupID: params[:lineupID])
        if @lineup
            render json: { lineups: @lineup }
        else
            render json: { error: "Lineup not found" }, status: :not_found
        end
    end

    # GET /lineups/player_lineup:playerID
    def player_lineup
        @lineup = Lineup.find_by(playerID: params[:playerID])
        if @lineup
            render json: { lineups: @lineup }
        else
            render json: { error: "Player lineup not found" }, status: :not_found
        end
    end

    # GET /lineups/team_lineup/:teamID
    def team_lineup
        @lineups = Lineup.where(teamID: params[:teamID])
        if @lineups
            render json: { lineups: @lineups }
        else
            render json: { error: "Team lineup not found" }, status: :not_found
        end
    end
end