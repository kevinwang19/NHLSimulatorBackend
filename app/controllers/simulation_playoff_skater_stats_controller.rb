class SimulationPlayoffSkaterStatsController < ApplicationController
    def self.initialize_simulation_playoff_skater_stats(simulation_id, playoff_lineups)
        errors = []

        playoff_lineups.select { |skater| skater["position"] != "G" }.each do |skater|
            simulation_stat = SimulationPlayoffSkaterStat.new(
                simulationID: simulation_id,
                playerID: skater["playerID"],
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

    # GET /simulation_playoff_skater_stats/simulation_team_playoff_stats?simulationID=:simulationID&playerIDs=:playerIDs&teamID=:teamID
    def simulation_team_playoff_stats
        if params[:teamID].to_i == 0
            @simulation_stats = SimulationPlayoffSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID])
                .select("\"simulation_playoff_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        else
            @simulation_stats = SimulationPlayoffSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID], playerID: params[:playerIDs])
                .select("\"simulation_playoff_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        end

        if @simulation_stats
            render json: { playoffSkaterStats: @simulation_stats }
        else
            render json: { error: "Skaters simulated playoff stats not found" }, status: :not_found
        end
    end

    # GET /simulation_playoff_skater_stats/simulation_team_position_playoff_stats?simulationID=:simulationID&playerIDs=:playerIDs&teamID=:teamID&postion=:position
    def simulation_team_position_playoff_stats
        if params[:teamID].to_i == 0
            @simulation_stats = SimulationPlayoffSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID])
                .where(players: { positionCode: params[:position] })
                .select("\"simulation_playoff_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        else
            @simulation_stats = SimulationPlayoffSkaterStat.joins(:player)
                .where(simulationID: params[:simulationID], playerID: params[:playerIDs])
                .where(players: { positionCode: params[:position] })
                .select("\"simulation_playoff_skater_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        end

        if @simulation_stats
            render json: { playoffSkaterStats: @simulation_stats }
        else
            render json: { error: "Skaters simulated playoff stats not found" }, status: :not_found
        end
    end
end