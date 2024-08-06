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
    
    # GET /simulation_skater_stats/simulation_individual_stat?simulationID=:simulationID&playerID=:playerID
    def simulation_individual_stat
        @simulation_stat = SimulationSkaterStat.find_by(simulationID: params[:simulationID], playerID: params[:playerID])
        
        if @simulation_stat
            render json: { skaterStats: @simulation_stat }
        else
            render json: { error: "Skater simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_skater_stats/simulation_team_stats?simulationID=:simulationID&teamID=:teamID
    def simulation_team_stats
        if params[:teamID] == 0
            @simulation_stats = SimulationSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID])
                .where("\"gamesPlayed\" > 0")
                .select("\"simulation_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        else
            player_ids = Player.where(teamID: params[:teamID]).pluck(:playerID)
            @simulation_stats = SimulationSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID], playerID: player_ids)
                .where("\"gamesPlayed\" > 0")
                .select("\"simulation_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        end

        if @simulation_stats
            render json: { skaterStats: @simulation_stats }
        else
            render json: { error: "Skaters simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_skater_stats/simulation_team_stats?simulationID=:simulationID&teamID=:teamID&postion=:position
    def simulation_team_position_stats
        if params[:teamID] == 0
            @simulation_stats = SimulationSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID])
                .where("\"gamesPlayed\" > 0")
                .where(players: { positionCode: params[:position] })
                .select("\"simulation_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        else
            player_ids = Player.where(teamID: params[:teamID]).pluck(:playerID)
            @simulation_stats = SimulationSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID], playerID: player_ids)
                .where("\"gamesPlayed\" > 0")
                .where(players: { positionCode: params[:position] })
                .select("\"simulation_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        end

        if @simulation_stats
            render json: { skaterStats: @simulation_stats }
        else
            render json: { error: "Skaters simulated stats not found" }, status: :not_found
        end
    end
end