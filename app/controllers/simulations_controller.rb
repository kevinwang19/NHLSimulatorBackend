require_relative "../../config/constants"

class SimulationsController < ApplicationController
    # POST /simulations
    def create
        @simulation = Simulation.new(simulation_params)
        current_date = Time.now

        if current_date.month < AUGUST_MONTH
            simulation_start_year = current_date.year - 1
            simulation_end_year = current_date.year
        else
            simulation_start_year = current_date.year
            simulation_end_year = current_date.year + 1
        end

        @simulation.season = "#{simulation_start_year}#{simulation_end_year}".to_i
        @simulation.status = "In progress"
        @simulation.simulationCurrentDate = "#{simulation_start_year}-10-01"

        if @simulation.save
            errors = []

            skater_stats_errors = SimulationSkaterStatsController.initialize_simulation_skater_stats(@simulation.simulationID)
            errors.concat(skater_stats_errors)

            goalie_stats_errors = SimulationGoalieStatsController.initialize_simulation_goalie_stats(@simulation.simulationID)
            errors.concat(goalie_stats_errors)

            team_stats_errors = SimulationTeamStatsController.initialize_simulation_team_stats(@simulation.simulationID)
            errors.concat(team_stats_errors)

            if errors.empty?
                render json: @simulation, status: :created
            else
                render json: { errors: errors }, status: :unprocessable_entity
            end
        else
            render json: { error: @simulation.errors}, status: :unprocessable_entity
        end  
    end

    def simulation_params
        params.require(:simulation).permit(:userID)
    end

    # PUT /simulations/simulate_to_date?simulationID=:simulationID&simulateDate=:simulateDate&playersAndLineups=:playersAndLineups&isPlayoffs=:isPlayoffs
    def simulate_to_date
        simulation_id = params.require(:simulationID)
        simulate_date = params.require(:simulateDate)
        players_and_lineups = params.require(:playersAndLineups)
        is_playoffs = params.require(:isPlayoffs)

        @simulation = Simulation.find_by(simulationID: simulation_id)

        if @simulation
            if is_playoffs
                playoff_game_simulator = Sim::PlayoffGameSimulator.new(@simulation)
                begin
                    playoff_game_simulator.simulate_playoff_games(players_and_lineups)
                    if @simulation.update(simulationCurrentDate: simulate_date)
                        render json: @simulation, status: :ok
                    else
                        render json: { error: "Failed to update simulation" }, status: :unprocessable_entity
                    end
                rescue => e
                    render json: { error: "Playoff simulation error: #{e.message}" }, status: :unprocessable_entity
                end
            else
                game_simulator = Sim::GameSimulator.new(@simulation)
                begin
                    game_simulator.simulate_games(players_and_lineups)
                    if @simulation.update(simulationCurrentDate: simulate_date)
                        render json: @simulation, status: :ok
                    else
                        render json: { error: "Failed to update simulation" }, status: :unprocessable_entity
                    end
                rescue => e
                    render json: { error: "Simulation error: #{e.message}" }, status: :unprocessable_entity
                end
            end
        else
            render json: { error: "Simulation not found" }, status: :not_found
        end
    end

    # PUT /simulations/finish?simulationID=:simulationID
    def finish
        @simulation = Simulation.find_by(simulationID: params[:simulationID])
        if @simulation.update(status: "Finished")
            render json: @simulation
        else
            render json: { error: @simulation.errors}, status: :unprocessable_entity
        end
    end

    # GET /simulations/user_simulation?userID=:userID
    def user_simulation
        @simulation = Simulation.where(userID: params[:userID]).order(simulationID: :desc).first
        if @simulation
            render json: @simulation
        else
            render json: { error: "User simulation not found" }, status: :not_found
        end
    end
end