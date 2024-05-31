class CreateGoalieStats < ActiveRecord::Migration[7.1]
    def change
        create_table :goalie_stats do |t|
            t.integer :playerID, null: false
            t.integer :season, null: false
            t.integer :gamesPlayed, null: false
            t.integer :gamesStarted, null: false
            t.integer :wins, null:false
            t.integer :losses, null: false
            t.integer :otLosses, null: false
            t.integer :goalsAgainst, null: false
            t.decimal :goalsAgainstAvg, null: false
            t.decimal :savePctg, null: false
            t.integer :shotsAgainst, null: false
            t.integer :shutouts, null: false

            t.timestamps
        end
    end
end
