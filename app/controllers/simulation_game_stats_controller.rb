class SimulationGameStatsController < ApplicationController
    # GET /simulation_game_stats
    def index
        @simulation_stats = SimulationGameStat.all
        render json: @simulation_stats
    end

    # GET /simulation_game_stats/:simulation_game_stat_id
    def show
        @simulation_stat = SimulationGameStat.find_by(simulationGameStatID: params[:simulation_game_stat_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_game_stats/game_simulated_stats/:simulation_id/:schedule_id
    def game_simulated_stats
        @simulation_stat = SimulationGameStat.find_by(simulationID: params[:simulation_id], scheduleID: params[:schedule_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Game simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_game_stats/simulation_stats/:simulation_id
    def simulation_stats
        @simulation_stats = SimulationGameStat.where(simulationID: params[:simulation_id])
        if @simulation_stats
            render json: @simulation_stats
        else
            render json: { error: "Games simulated stats not found" }, status: :not_found
        end
    end
end