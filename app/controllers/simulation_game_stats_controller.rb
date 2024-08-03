class SimulationGameStatsController < ApplicationController
    # GET /simulation_game_stats/team_simulated_game_stats?simulationID=:simulationID&currentDate=:currentDate&teamID=:teamID&season=:season
    def team_simulated_game_stats
        date = Date.parse(params[:currentDate])

        schedules = Schedule.where(
            "(\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND season = :season AND date < :currentDate", 
            teamID: params[:teamID], 
            season: params[:season],
            currentDate: params[:currentDate]
        )

        schedule_ids = schedules.pluck(:scheduleID)

        @simulation_stats = SimulationGameStat.where(simulationID: params[:simulationID], scheduleID: schedule_ids)
  
        if @simulation_stats
            render json: { gameStats: @simulation_stats }
        else
            render json: { gameStats: [] }
        end
    end
end