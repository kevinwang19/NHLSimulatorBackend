class CreatePlayerStats < ActiveRecord::Migration[7.1]
    def change
        create_table :player_stats do |t|
            t.integer :playerID, null: false
            t.integer :season, null: false
            t.integer :gamesPlayed, null: false
            t.integer :goals, null: false
            t.integer :assists, null: false
            t.integer :points, null: false
            t.string :avgToi, null: false
            t.decimal :faceoffWinningPctg, null: false
            t.integer :gameWinningGoals, null: false
            t.integer :otGoals, null: false
            t.integer :pim, null: false
            t.integer :plusMinus, null: false
            t.integer :powerPlayGoals, null: false
            t.integer :powerPlayPoints, null: false
            t.decimal :shootingPctg, null: false
            t.integer :shorthandedGoals, null: false
            t.integer :shorthandedPoints, null: false
            t.integer :shots, null: false

            t.timestamps
        end
    end
end
