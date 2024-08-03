class SimulationGoalieStatsController < ApplicationController
    def self.initialize_simulation_goalie_stats(simulation_id)
        errors = []

        Lineup.where.not(teamID: nil).where(position: "G").find_each do |goalie|
            simulation_stat = SimulationGoalieStat.new(
                simulationID: simulation_id,
                playerID: goalie.playerID,
                gamesPlayed: 0,
                wins: 0,
                losses: 0,
                otLosses: 0,
                goalsAgainstPerGame: 0.0,
                shutouts: 0
            )

            unless simulation_stat.save
                errors << simulation_stat.errors.full_messages
            end
        end

        errors
    end
    
    # GET /simulation_goalie_stats
    def index
        @simulation_stats = SimulationGoalieStat.all
        render json: { simulation_goalie_stats: @simulation_stats }
    end

    # GET /simulation_goalie_stats/:simulationID/:playerID
    def show
        @simulation_stat = SimulationGoalieStat.find_by(simulationID: params[:simulationID], playerID: params[:playerID])
        if @simulation_stat
            render json: { simulation_goalie_stats: @simulation_stat }
        else
            render json: { error: "Goalie simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_goalie_stats/simulation_stats/:simulationID
    def simulation_stats
        @simulation_stats = SimulationGoalieStat.where(simulationID: params[:simulationID])

        if @simulation_stats
            render json: { simulation_goalie_stats: @simulation_stats }
        else
            render json: { error: "Goalies simulated stats not found" }, status: :not_found
        end
    end
end