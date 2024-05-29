class TeamsController < ApplicationController
    # GET /teams
    def index
        @teams = Team.all
        render json: @teams
    end

    # GET /teams/:teamID
    def show
        @team = Team.find_by(teamID: params[:teamID])
        if @team
            render json: @team
        else
            render json: { error: "Team not found" }, status: :not_found
        end
    end
end