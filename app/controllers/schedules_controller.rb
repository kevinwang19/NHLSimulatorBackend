class SchedulesController < ApplicationController
    # GET /schedules
    def index
        @schedules = Schedule.all
        render json: @schedules
    end

    # GET /schedules/:date
    def show
        @schedules = Schedule.where(date: params[:date])
        if @schedules.any?
            render json: @schedules
        else
            render json: { error: "Schedule not found for the date" }, status: :not_found
        end
    end
end