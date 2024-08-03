class PlayersController < ApplicationController
    # GET /players
    def index
        @players = Player.where.not(teamID: nil)
        render json: { players: @players }
    end

    # GET /players/:playerID
    def show
        @player = Player.find_by(playerID: params[:playerID])
        if @player
            render json: { players: @player }
        else
            render json: { error: "Player not found" }, status: :not_found
        end
    end

    # GET /players/:firstName/:lastName/:positionCode
    def name_player
        @player = Player.find_by(firstName: params[:firstName], lastName: params[:lastName], positionCode: params[:positionCode])
        if @player
            render json: { players: @player }
        else
            render json: { error: "Player details not found" }, status: :not_found
        end
    end

    # GET /players/team_players/:teamID
    def team_players
        @players = Player.where(teamID: params[:teamID])
        if @players
            render json: { players: @players }
        else
            render json: { error: "Team players not found" }, status: :not_found
        end
    end
end