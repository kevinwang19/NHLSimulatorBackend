require_relative "../../config/constants"

class SimulationsController < ApplicationController
    # POST /simulations
    def create
        @simulation = Simulation.new(simulation_params)
        current_date = Time.now

        if current_date.month < SEPTEMBER_MONTH
            simulation_start_year = current_date.prev_year
            simulation_end_year = current_date.year
        else
            simulation_start_year = current_date.year
            simulation_end_year = current_date.next_year
        end

        @simulation.season = (simulation_start_year.to_s + simulation_end_year.to_s).to_i
        @simulation.status = "In progress"
        @simulation.simulationCurrentDate = "#{simulation_start_year}-10-01"

        if @simulation.save
            SimulationPlayerStatsController.new.create({ simulationID: @simulation.simulationID })
            SimulationTeamStatsController.new.create({ simulationID: @simulation.simulationID })
            render json: @simulation, status: :created
        else
            render json: @simulation.errors, status: :unprocessable_entity
        end  
    end

    def simulation_params
        params.require(:simulation).permit(:userID)
    end

    # POST /simulations/simulate_to_date/:simulation_id/:simulate_date
    def simulate_to_date
        @simulation = Simulation.find(params[:simulation_id])

        if @simulation
            game_simulator = GameSimulator.new(@simulation)
            game_simulator.simulate_games(params[:simulate_date])
            @simulation.simulationCurrentDate = params[:simulate_date]

            render json: @simulation, status: :ok
        else
            render json: { error: "Simulation up to date not found" }, status: :not_found
        end
    end

    # PUT /simulations/finish/:simulation_id
    def finish
        @simulation = Simulation.find(params[:simulation_id])
        if @simulation.update(status: "Finished")
            render json: @simulation
        else
            render json: @simulation.errors, status: :unprocessable_entity
        end
    end

    # GET /simulations
    def index
        @simulations = Simulation.all
        render json: @simulations
    end

    # GET /simulations/:simulation_id
    def show
        @simulation = Simulation.find(params[:simulation_id])
        render json: @simulation
    end
end