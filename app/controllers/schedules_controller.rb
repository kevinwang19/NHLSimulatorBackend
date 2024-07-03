class SchedulesController < ApplicationController
    # GET /schedules
    def index
        @schedules = Schedule.where.not(awayTeamID: nil).where.not(homeTeamID: nil)
        render json: @schedules
    end

    # GET /schedules/:schedule_id
    def show
        @schedule = Schedule.find_by(scheduleID: params[:schedule_id])
        if @schedule
            render json: @schedule
        else
            render json: { error: "Schedule not found" }, status: :not_found
        end
    end

    # GET /schedules/game_schedules/:date/:away_team_id/:home_team_id
    def game_schedule
        @schedule = Schedule.find_by(date: params[:date], awayTeamID: params[:away_team_id], homeTeamID: params[:home_team_id])
        if @schedule
            render json: @schedule
        else
            render json: { error: "Schedule not found for the game" }, status: :not_found
        end
    end

    # GET /schedules/date_schedules/:date
    def date_schedules
        @schedules = Schedule.where(date: params[:date])
        if @schedules
            render json: @schedules
        else
            render json: { error: "Schedule not found for the date" }, status: :not_found
        end
    end

     # GET /schedules/team_season_schedules/:team_id/:season
     def team_season_schedules
        @schedules = Schedule.where("awayTeamID = :teamID OR homeTeamID = :teamID", teamID: params[:team_id], season: params[:season])
        if @schedules
            render json: @schedules
        else
            render json: { error: "Season schedule not found for the team" }, status: :not_found
        end
    end
end