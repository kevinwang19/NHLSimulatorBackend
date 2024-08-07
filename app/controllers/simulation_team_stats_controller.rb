class SimulationTeamStatsController < ApplicationController
    def self.initialize_simulation_team_stats(simulation_id)
        errors = []
        league_rank = 0

        teams = Team.where(isActive: true).pluck(:teamID, :conference, :division)

        teams.group_by { |team| team[1] }.each do |conference, conference_teams|
            conference_rank = 0

            conference_teams.group_by { |team| team[2] }.each do |division, division_teams|
                division_rank = 0
                
                division_teams.each do |team|
                    division_rank += 1
                    conference_rank += 1
                    league_rank += 1
                    
                    simulation_stat = SimulationTeamStat.new(
                        simulationID: simulation_id,
                        teamID: team[0],
                        gamesPlayed: 0,
                        wins: 0,
                        losses: 0,
                        otLosses: 0,
                        points: 0,
                        goalsFor: 0,
                        goalsForPerGame: 0.0,
                        goalsAgainst: 0,
                        goalsAgainstPerGame: 0.0,
                        totalPowerPlays: 0,
                        powerPlayPctg: 0.0,
                        totalPenaltyKills: 0,
                        penaltyKillPctg: 0.0,
                        divisionRank: division_rank,
                        conferenceRank: conference_rank,
                        leagueRank: league_rank,
                        isWildCard: false,
                        isPresidents: false
                    )

                    unless simulation_stat.save
                        errors << simulation_stat.errors.full_messages
                    end
                end
            end
        end

        errors
    end

    # GET /simulation_team_stats/team_simulated_stats?simulationID=:simulationID&teamID=:teamID
    def team_simulated_stats
        @simulation_stat = SimulationTeamStat.joins(:team)
            .where(simulationID: params[:simulationID], teamID: params[:teamID])
            .select("\"simulation_team_stats\".*, \"teams\".\"fullName\"")
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
                points: @simulation_stat.points,
                goalsFor: @simulation_stat.goalsFor,
                goalsForPerGame: @simulation_stat.goalsForPerGame.to_f,
                goalsAgainst: @simulation_stat.goalsAgainst,
                goalsAgainstPerGame: @simulation_stat.goalsAgainstPerGame.to_f,
                totalPowerPlays: @simulation_stat.totalPowerPlays,
                powerPlayPctg: @simulation_stat.powerPlayPctg.to_f,
                totalPenaltyKills: @simulation_stat.totalPenaltyKills,
                penaltyKillPctg: @simulation_stat.penaltyKillPctg.to_f,
                divisionRank: @simulation_stat.divisionRank,
                conferenceRank: @simulation_stat.conferenceRank,
                leagueRank: @simulation_stat.leagueRank,
                isWildCard: @simulation_stat.isWildCard,
                isPresidents: @simulation_stat.isPresidents
            }
        else
            render json: { error: "Team simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_team_stats/simulation_all_stats?simulationID=:simulationID
    def simulation_all_stats
        @simulation_stats = SimulationTeamStat.joins(:team)
            .where(simulationID: params[:simulationID])
            .select("\"simulation_team_stats\".*, \"teams\".\"fullName\"")

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
                    points: stat.points,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f,
                    divisionRank: stat.divisionRank,
                    conferenceRank: stat.conferenceRank,
                    leagueRank: stat.leagueRank,
                    isWildCard: stat.isWildCard,
                    isPresidents: stat.isPresidents
                }
            end
            render json: { teamStats: serialized_stats }
        else
            render json: { error: "League simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_team_stats/simulation_conference_stats?simulationID=:simulationID&conference=:conference
    def simulation_conference_stats
        @simulation_stats = SimulationTeamStat.joins(:team)
            .where(simulationID: params[:simulationID])
            .where("LOWER(\"teams\".\"conference\") IN (?)", params[:conference].map(&:downcase))
            .select("\"simulation_team_stats\".*, \"teams\".\"fullName\"")

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
                    points: stat.points,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f,
                    divisionRank: stat.divisionRank,
                    conferenceRank: stat.conferenceRank,
                    leagueRank: stat.leagueRank,
                    isWildCard: stat.isWildCard,
                    isPresidents: stat.isPresidents
                }
            end
            render json: { teamStats: serialized_stats }
        else
            render json: { error: "Conference simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_team_stats/simulation_division_stats?simulationID=:simulationID&division=:division
    def simulation_division_stats
        @simulation_stats = SimulationTeamStat.joins(:team)
        .where(simulationID: params[:simulationID])
        .where("LOWER(\"teams\".\"division\") IN (?)", params[:division].map(&:downcase))
        .select("\"simulation_team_stats\".*, \"teams\".\"fullName\"")

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
                    points: stat.points,
                    goalsFor: stat.goalsFor,
                    goalsForPerGame: stat.goalsForPerGame.to_f,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstPerGame: stat.goalsAgainstPerGame.to_f,
                    totalPowerPlays: stat.totalPowerPlays,
                    powerPlayPctg: stat.powerPlayPctg.to_f,
                    totalPenaltyKills: stat.totalPenaltyKills,
                    penaltyKillPctg: stat.penaltyKillPctg.to_f,
                    divisionRank: stat.divisionRank,
                    conferenceRank: stat.conferenceRank,
                    leagueRank: stat.leagueRank,
                    isWildCard: stat.isWildCard,
                    isPresidents: stat.isPresidents
                }
            end
            render json: { teamStats: serialized_stats }
        else
            render json: { error: "Division simulated stats not found" }, status: :not_found
        end
    end
end