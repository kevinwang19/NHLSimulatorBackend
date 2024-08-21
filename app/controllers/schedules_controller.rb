class SchedulesController < ApplicationController
    # GET /schedules/team_date_schedule?teamID=:teamID&date=:date
    def team_date_schedule
        @schedule = Schedule.find_by(
            "(\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND date = :date", 
            teamID: params[:teamID], 
            date: params[:date]
        )
  
        if @schedule
            render json: { schedules: [@schedule]}
        else
            render json: { schedules: [] }
        end
    end

    # GET /schedules/team_month_schedules?teamID=:teamID&season=:season&month=:month
    def team_month_schedules
        month_string = params[:month].to_s.rjust(2, "0") # Ensure the month is two digits
        @schedules = Schedule.where(
            "(\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND SUBSTRING(date, 6, 2) = :month AND season = :season", 
            teamID: params[:teamID], 
            season: params[:season],
            month: month_string
        )
  
        if @schedules
            render json: { schedules: @schedules }
        else
            render json: { error: "Month schedule not found for the team" }, status: :not_found
        end
    end

    # GET /schedules/last_schedule?season=:season
    def last_schedule
        @schedule = Schedule.where(season: params[:season]).last
  
        if @schedule
            render json: @schedule
        else
            render json: { error: "Last schedule not found" }, status: :not_found
        end
    end
end