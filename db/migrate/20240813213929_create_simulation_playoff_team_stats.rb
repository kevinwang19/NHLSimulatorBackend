class CreateSimulationPlayoffTeamStats < ActiveRecord::Migration[7.1]
    def change
        create_table :simulation_playoff_team_stats, id: false do |t|
            t.primary_key :simulationPlayoffTeamStatID
            t.integer :simulationID, null: false
            t.integer :teamID, null: false
            t.integer :gamesPlayed, null: false, default: 0
            t.integer :wins, null: false, default: 0
            t.integer :losses, null: false, default: 0
            t.integer :otLosses, null: false, default: 0
            t.integer :goalsFor, null: false, default: 0
            t.float :goalsForPerGame, null: false, default: 0.0
            t.integer :goalsAgainst, null: false, default: 0
            t.float :goalsAgainstPerGame, null: false, default: 0.0
            t.integer :totalPowerPlays, null: false, default: 0
            t.float :powerPlayPctg, null: false, default: 0.0
            t.integer :totalPenaltyKills, null: false, default: 0
            t.float :penaltyKillPctg, null: false, default: 0.0

            t.timestamps
        end

        add_foreign_key :simulation_playoff_team_stats, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :simulation_playoff_team_stats, :teams, column: :teamID, primary_key: :teamID
    end
end
