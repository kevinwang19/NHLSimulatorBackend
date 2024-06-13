class LineupsController < ApplicationController
    # GET /lineups
    def index
        @lineups = Lineup.all
        render json: @lineups
    end

    # GET /lineups/:teamID
    def show
        @lineup = Lineup.where(teamID: params[:teamID])
        if @lineup
            render json: @lineup
        else
            render json: { error: "Team lineup not found" }, status: :not_found
        end
    end
end