class TeamsController < ApplicationController
    # GET /teams
    def index
        @teams = Team.where(isActive: true).order(:fullName)
        render json: { teams: @teams }
    end

    # GET /teams/team?teamID=:teamID
    def team
        @team = Team.find_by(teamID: params[:teamID])
        if @team
            render json: @team
        else
            render json: { error: "Team not found" }, status: :not_found
        end
    end
end