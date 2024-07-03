class CreateSimulationTeamStats < ActiveRecord::Migration[7.1]
    def change
        create_table :simulation_team_stats, id: false do |t|
            t.primary_key :simulationTeamStatID
            t.integer :simulationID, null: false
            t.integer :teamID, null: false
            t.integer :gamesPlayed, null: false, default: 0
            t.integer :wins, null: false, default: 0
            t.integer :losses, null: false, default: 0
            t.integer :otLosses, null: false, default: 0
            t.integer :points, null: false, default: 0
            t.integer :goalsFor, null: false, default: 0
            t.decimal :goalsForPerGame, null: false, default: 0.0
            t.integer :goalsAgainst, null: false, default: 0
            t.decimal :goalsAgainstPerGame, null: false, default: 0.0
            t.integer :totalPowerPlays, null: false, default: 0
            t.decimal :powerPlayPctg, null: false, default: 0.0
            t.integer :totalPenaltyKills, null: false, default: 0
            t.decimal :penaltyKillPctg, null: false, default: 0.0
            t.integer :divisionRank
            t.integer :conferenceRank
            t.integer :leagueRank
            t.boolean :isWildCard
            t.boolean :isPresidents

            t.timestamps
        end

        add_foreign_key :simulation_team_stats, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :simulation_team_stats, :teams, column: :teamID, primary_key: :teamID
    end
end
