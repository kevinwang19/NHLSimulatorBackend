class PlayersController < ApplicationController
    # GET /players
    def index
        @players = Player.where.not(teamID: nil)
        render json: { players: @players }
    end
end