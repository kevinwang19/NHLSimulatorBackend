class PlayersController < ApplicationController
    # GET /players
    def index
        @players = Player.all
        render json: @players
    end

    # GET /players/:teamID
    def show
        @team = Team.find_by(teamID: params[:teamID])
        if @team
            @players = @team.players.where(isActive: true)
            render json: @players
        else
            render json: { error: "Team players not found" }, status: :not_found
        end
    end
end