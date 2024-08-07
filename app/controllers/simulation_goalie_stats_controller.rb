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

    # GET /simulation_goalie_stats/simulation_individual_stat?simulationID=:simulationID&playerID=:playerID
    def simulation_individual_stat
        @simulation_stat = SimulationGoalieStat.find_by(simulationID: params[:simulationID], playerID: params[:playerID])
        
        if @simulation_stat
            render json: { goalieStats: @simulation_stat }
        else
            render json: { error: "Goalie simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_goalie_stats/simulation_team_stats?simulationID=:simulationID&teamID=:teamID
    def simulation_team_stats
        if params[:teamID].to_i == 0
            @simulation_stats = SimulationGoalieStat.joins(:player)
                .where(simulationID: params[:simulationID])
                .where("\"gamesPlayed\" > 0")
                .select("\"simulation_goalie_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        else
            player_ids = Player.where(teamID: params[:teamID]).pluck(:playerID)
            @simulation_stats = SimulationGoalieStat.joins(:player)
                .where(simulationID: params[:simulationID], playerID: player_ids)
                .where("\"gamesPlayed\" > 0")
                .select("\"simulation_goalie_stats\".*, CONCAT(\"players\".\"firstName\", ' ', \"players\".\"lastName\") AS \"fullName\"")
        end

        if @simulation_stats
            render json: { goalieStats: @simulation_stats }
        else
            render json: { error: "Goalies simulated stats not found" }, status: :not_found
        end
    end
end