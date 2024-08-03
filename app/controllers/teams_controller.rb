class TeamsController < ApplicationController
    # GET /teams
    def index
        @teams = Team.where(isActive: true).order(:fullName)
        render json: { teams: @teams }
    end
end