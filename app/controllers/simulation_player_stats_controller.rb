class SimulationPlayerStatsController < ApplicationController
    # POST /simulation_player_stats/:simulation_id
    def create
        errors = []

        Player.where.not(teamID: nil).find_each do |player|
            if player.positionCode == "G"
                simulation_stat = SimulationGoalieStat.new(
                    simulationID: params[:simulation_id],
                    playerID: player.playerID,
                    gamesPlayed: 0,
                    wins: 0,
                    losses: 0,
                    otLosses: 0,
                    goalsAgainstPerGame: 0.0,
                    shutouts: 0
                )
            else
                simulation_stat = SimulationSkaterStat.new(
                    simulationID: params[:simulation_id],
                    playerID: player.playerID,
                    gamesPlayed: 0,
                    goals: 0,
                    assists: 0,
                    points: 0,
                    powerPlayGoals: 0,
                    powerPlayPoints: 0
                )
            end

            unless simulation_stat.save
                errors << simulation_stat.errors.full_messages
            end
        end

        if errors.empty?
            render json: { message: "Simulation stats initialized" }, status: :created
        else
            render json: { errors: errors }, status: :unprocessable_entity
        end
    end
    
    # GET /simulation_player_stats
    def index
        @simulation_stats = SimulationSkaterStat.all + SimulationGoalieStat.all
        render json: @simulation_stats
    end

    # GET /simulation_player_stats/:position_code/:simulation_stat_id
    def show
        @simulation_stat = params[:position_code] == "G" ? 
            SimulationGoalieStat.find_by(simulationGoalieStatID: params[:simulation_stat_id]) : 
            SimulationSkaterStat.find_by(simulationSkaterStatID: params[:simulation_stat_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_player_stats/player_simulated_stats/:simulation_id/:player_id
    def player_simulated_stats
        @player = Player.find_by(playerID: params[:player_id])
        @simulation_stat = @player.position == "G" ? 
            SimulationGoalieStat.find_by(simulationID: params[:simulation_id], playerID: params[:player_id]) : 
            SimulationSkaterStat.find_by(simulationID: params[:simulation_id], playerID: params[:player_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Player simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_player_stats/simulation_stats/:simulation_id
    def simulation_stats
        @simulation_stats = SimulationSkaterStat.where(simulationID: params[:simulation_id]) + 
                            SimulationGoalieStat.where(simulationID: params[:simulation_id])
        if @simulation_stats
            render json: @simulation_stats
        else
            render json: { error: "Players simulated stats not found" }, status: :not_found
        end
    end
end