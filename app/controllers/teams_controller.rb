class TeamsController < ApplicationController
    # GET /teams
    def index
        @teams = Team.where(isActive: true)
        render json: @teams
    end

    # GET /teams/:team_id
    def show
        @team = Team.find_by(teamID: params[:team_id])
        if @team
            render json: @team
        else
            render json: { error: "Team not found" }, status: :not_found
        end
    end

    # GET /teams/abbrev_team/:abbrev
    def abbrev_team
        @team = Team.find_by(abbrev: params[:abbrev])
        if @team
            render json: @team
        else
            render json: { error: "Team abbreviation not found" }, status: :not_found
        end
    end
end