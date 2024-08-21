class CreateSimulationPlayoffSkaterStats < ActiveRecord::Migration[7.1]
    def change
        create_table :simulation_playoff_skater_stats, id: false do |t|
            t.primary_key :simulationPlayoffSkaterStatID
            t.integer :simulationID, null: false
            t.integer :playerID, null: false
            t.integer :gamesPlayed, null: false, default: 0
            t.integer :goals, null: false, default: 0
            t.integer :assists, null: false, default: 0
            t.integer :points, null: false, default: 0
            t.integer :powerPlayGoals, null: false, default: 0
            t.integer :powerPlayPoints, null: false, default: 0
            
            t.timestamps
        end

        add_foreign_key :simulation_playoff_skater_stats, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :simulation_playoff_skater_stats, :players, column: :playerID, primary_key: :playerID
    end
end
