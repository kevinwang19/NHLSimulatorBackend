class PlayersController < ApplicationController
    # GET /players
    def index
        @players = Player.where.not(teamID: nil)
        render json: @players
    end

    # GET /players/:player_id
    def show
        @player = Player.find_by(playerID: params[:player_id])
        if @player
            render json: @player
        else
            render json: { error: "Player not found" }, status: :not_found
        end
    end

    # GET /players/:first_name/:last_name/:position_code
    def name_player
        @player = Player.find_by(firstName: params[:first_name], lastName: params[:last_name], positionCode: params[:position_code])
        if @player
            render json: @player
        else
            render json: { error: "Player details not found" }, status: :not_found
        end
    end

    # GET /players/team_players/:team_id
    def team_players
        @players = Player.where(teamID: params[:team_id])
        if @players
            render json: @players
        else
            render json: { error: "Team players not found" }, status: :not_found
        end
    end
end