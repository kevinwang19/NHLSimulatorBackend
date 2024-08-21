class CreateSimulationPlayoffGoalieStats < ActiveRecord::Migration[7.1]
    def change
        create_table :simulation_playoff_goalie_stats, id: false do |t|
            t.primary_key :simulationPlayoffGoalieStatID
            t.integer :simulationID, null: false
            t.integer :playerID, null: false
            t.integer :gamesPlayed, null: false, default: 0
            t.integer :wins, null: false, default: 0
            t.integer :losses, null: false, default: 0
            t.integer :otLosses, null: false, default: 0
            t.float :goalsAgainstPerGame, null: false, default: 0.0
            t.integer :shutouts, null: false, default: 0
            
            t.timestamps
        end

        add_foreign_key :simulation_playoff_goalie_stats, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :simulation_playoff_goalie_stats, :players, column: :playerID, primary_key: :playerID
    end
end
