class SimulationTeamStatsController < ApplicationController
    # POST /simulation_team_stats/:simulation_id
    def create
        errors = []
        league_rank = 0

        Team.where(isActive: true).group(:conference).each do |_, conference_teams|
            conference_rank = 0

            conference_teams.group(:division).each do |_, division_teams|
                division_rank = 0
                
                division_teams.each do |team|
                    division_rank += 1
                    conference_rank += 1
                    league_rank += 1
                    
                    simulation_stat = SimulationTeamStat.new(
                        simulationID: params[:simulation_id],
                        teamID: team.teamID,
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

        if errors.empty?
            render json: { message: "Simulation team stats initialized" }, status: :created
        else
            render json: { errors: errors }, status: :unprocessable_entity
        end
    end
    
    # GET /simulation_team_stats
    def index
        @simulation_stats = SimulationTeamStat.all
        render json: @simulation_stats
    end

    # GET /simulation_team_stats/:simulation_team_stat_id
    def show
        @simulation_stat = SimulationTeamStat.find_by(simulationTeamStatID: params[:simulation_team_stat_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_team_stats/team_simulated_stats/:simulation_id/:team_id
    def team_simulated_stats
        @simulation_stat = SimulationTeamStat.find_by(simulationID: params[:simulation_id], teamID: params[:team_id])
        if @simulation_stat
            render json: @simulation_stat
        else
            render json: { error: "Team simulated stats not found" }, status: :not_found
        end
    end

    # GET /simulation_player_stats/simulation_stats/:simulation_id
    def simulation_stats
        @simulation_stats = SimulationTeamStat.where(simulationID: params[:simulation_id])
        if @simulation_stats
            render json: @simulation_stats
        else
            render json: { error: "Teams simulated stats not found" }, status: :not_found
        end
    end
end