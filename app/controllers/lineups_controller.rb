class LineupsController < ApplicationController
    # GET /lineups
    def index
        @lineups = Lineup.where.not(teamID: nil)
        render json: { lineups: @lineups }
    end
end