class SimulationSkaterStatsController < ApplicationController
    def self.initialize_simulation_skater_stats(simulation_id)
        errors = []

        Lineup.where.not(teamID: nil).where.not(position: "G").find_each do |skater|
            simulation_stat = SimulationSkaterStat.new(
                simulationID: simulation_id,
                playerID: skater.playerID,
                gamesPlayed: 0,
                goals: 0,
                assists: 0,
                points: 0,
                powerPlayGoals: 0,
                powerPlayPoints: 0
            )

            unless simulation_stat.save
                errors << simulation_stat.errors.full_messages
            end
        end

        errors
    end
    
    # GET /simulation_skater_stats
    def index
        @simulation_stats = SimulationSkaterStat.all
        render json: { simulation_skater_stats: @simulation_stats }
    end

    # GET /simulation_skater_stats/:simulationID/:playerID
    def show
        @simulation_stat = SimulationSkaterStat.find_by(simulationID: params[:simulationID], playerID: params[:playerID])
        if @simulation_stat
            render json: { simulation_skater_stats: @simulation_stat }
        else
            render json: { error: "Skater simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_skater_stats/simulation_stats/:simulationID
    def simulation_stats
        @simulation_stats = SimulationSkaterStat.where(simulationID: params[:simulationID])

        if @simulation_stats
            render json: { simulation_skater_stats: @simulation_stats }
        else
            render json: { error: "Skaters simulated stats not found" }, status: :not_found
        end
    end
end