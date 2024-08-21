class SimulationPlayoffTeamStatsController < ApplicationController
    def self.initialize_simulation_playoff_team_stats(simulation_id)
        errors = []
        playoff_teams = SimulationTeamStat.where(simulationID: simulation_id)
                            .where("\"divisionRank\" IN (?) OR \"isWildCard\" = ?", [1, 2, 3], true)

        playoff_teams.each do |team|
            simulation_stat = SimulationPlayoffTeamStat.new(
                simulationID: simulation_id,
                teamID: team.teamID,
                gamesPlayed: 0,
                wins: 0,
                losses: 0,
                otLosses: 0,
                goalsFor: 0,
                goalsForPerGame: 0.0,
                goalsAgainst: 0,
                goalsAgainstPerGame: 0.0,
                totalPowerPlays: 0,
                powerPlayPctg: 0.0,
                totalPenaltyKills: 0,
                penaltyKillPctg: 0.0
            )

            unless simulation_stat.save
                errors << simulation_stat.errors.full_messages
            end
        end

        errors
    end

    # GET /simulation_playoff_team_stats/playoff_team_simulated_stats?simulationID=:simulationID&teamID=:teamID
    def playoff_team_simulated_stats
        @simulation_stat = SimulationPlayoffTeamStat.joins(:team)
            .where(simulationID: params[:simulationID], teamID: params[:teamID])
            .select("\"simulation_playoff_team_stats\".*, \"teams\".\"fullName\"")
            .first

        if @simulation_stat
            render json: {
                simulationID: @simulation_stat.simulationID,
                teamID: @simulation_stat.teamID,
                fullName: @simulation_stat.fullName,
                gamesPlayed: @simulation_stat.gamesPlayed,
                wins: @simulation_stat.wins,
                losses: @simulation_stat.losses,
                otLosses: @simulation_stat.otLosses,
                goalsFor: @simulation_stat.goalsFor,
                goalsForPerGame: @simulation_stat.goalsForPerGame.to_f,
                goalsAgainst: @simulation_stat.goalsAgainst,
                goalsAgainstPerGame: @simulation_stat.goalsAgainstPerGame.to_f,
                totalPowerPlays: @simulation_stat.totalPowerPlays,
                powerPlayPctg: @simulation_stat.powerPlayPctg.to_f,
                totalPenaltyKills: @simulation_stat.totalPenaltyKills,
                penaltyKillPctg: @simulation_stat.penaltyKillPctg.to_f
            }
        else
            render json: {
                simulationID: 0,
                teamID: 0,
                fullName: "",
                gamesPlayed: 0,
                wins: 0,
                losses: 0,
                otLosses: 0,
                goalsFor: 0,
                goalsForPerGame: 0.0,
                goalsAgainst: 0,
                goalsAgainstPerGame: 0.0,
                totalPowerPlays: 0,
                powerPlayPctg: 0.0,
                totalPenaltyKills: 0,
                penaltyKillPctg: 0.0
            }
        end
    end

    # GET /simulation_playoff_team_stats/simulation_all_playoff_stats?simulationID=:simulationID
    def simulation_all_playoff_stats
        @simulation_stats = SimulationPlayoffTeamStat.joins(:team)
            .where(simulationID: params[:simulationID])
            .select("\"simulation_playoff_team_stats\".*, \"teams\".\"fullName\"")

        if @simulation_stats
            serialized_stats = @simulation_stats.map do |stat|
                {
                    simulationID: stat.simulationID,
                    teamID: stat.teamID,
                    fullName: stat.fullName,
                    gamesPlayed: stat.gamesPlayed,
                    wins: stat.wins,
                    losses: stat.losses,
                    otLosses: stat.otLosses,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f
                }
            end
            render json: { playoffTeamStats: serialized_stats }
        else
            render json: { error: "League simulated playoff stats not found" }, status: :not_found
        end
    end

    # GET /simulation_playoff_team_stats/simulation_conference_playoff_stats?simulationID=:simulationID&conference=:conference
    def simulation_conference_playoff_stats
        @simulation_stats = SimulationPlayoffTeamStat.joins(:team)
            .where(simulationID: params[:simulationID])
            .where("LOWER(\"teams\".\"conference\") IN (?)", params[:conference].map(&:downcase))
            .select("\"simulation_playoff_team_stats\".*, \"teams\".\"fullName\"")

        if @simulation_stats
            serialized_stats = @simulation_stats.map do |stat|
                {
                    simulationID: stat.simulationID,
                    teamID: stat.teamID,
                    fullName: stat.fullName,
                    gamesPlayed: stat.gamesPlayed,
                    wins: stat.wins,
                    losses: stat.losses,
                    otLosses: stat.otLosses,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f
                }
            end
            render json: { playoffTeamStats: serialized_stats }
        else
            render json: { error: "Conference simulated playoff stats not found" }, status: :not_found
        end
    end

    # GET /simulation_playoff_team_stats/simulation_playoff_tree?simulationID=:simulationID&conference=:conference
    def simulation_playoff_tree
        @simulation_stats = PlayoffSchedule.select("DISTINCT ON (simulation_playoff_team_stats.\"teamID\", playoff_schedules.\"roundNumber\", playoff_schedules.\"matchupNumber\", playoff_schedules.\"conference\") playoff_schedules.*, simulation_playoff_team_stats.*")
            .joins("INNER JOIN simulation_playoff_team_stats ON simulation_playoff_team_stats.\"simulationID\" = playoff_schedules.\"simulationID\" AND (simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"awayTeamID\" OR simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"homeTeamID\")")
            .where(playoff_schedules: { simulationID: params[:simulationID] })
            .where("LOWER(\"playoff_schedules\".\"conference\") IN (?)", params[:conference].downcase)
            .order("playoff_schedules.\"roundNumber\" ASC, playoff_schedules.\"matchupNumber\" ASC")

        if @simulation_stats
            serialized_stats = @simulation_stats.map do |stat|
                {
                    simulationID: stat.simulationID,
                    teamID: stat.teamID,
                    fullName: stat.teamID == stat.awayTeamID ? stat.awayTeamAbbrev : stat.homeTeamAbbrev,
                    gamesPlayed: stat.gamesPlayed,
                    wins: stat.wins,
                    losses: stat.losses,
                    otLosses: stat.otLosses,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f
                }
            end
            render json: { playoffTeamStats: serialized_stats }
        else
            render json: { error: "Conference simulated playoff stats not found" }, status: :not_found
        end
    end
end