class CreateSimulationGameStats < ActiveRecord::Migration[7.1]
    def change
        create_table :simulation_game_stats, id: false do |t|
            t.primary_key :simulationGameStatID
            t.integer :simulationID, null: false
            t.integer :scheduleID
            t.integer :awayTeamID, null: false
            t.integer :awayTeamScore, null: false
            t.integer :homeTeamID, null: false
            t.integer :homeTeamScore, null: false

            t.timestamps
        end

        add_foreign_key :simulation_game_stats, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :simulation_game_stats, :schedules, column: :scheduleID, primary_key: :scheduleID
    end
end
