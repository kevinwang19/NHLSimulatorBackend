class CreateSchedules < ActiveRecord::Migration[7.1]
    def change
        create_table :schedules do |t|
            t.string :date, null: false
            t.string :dayAbbrev, null: false
            t.integer :season, null: false
            t.integer :awayTeamID, null: false
            t.string :awayTeamAbbrev, null: false
            t.string :awayTeamLogo, null: false
            t.integer :homeTeamID, null: false
            t.string :homeTeamAbbrev, null: false
            t.string :homeTeamLogo, null: false
            t.string :score

            t.timestamps
        end

        add_index :schedules, [:date, :awayTeamID, :homeTeamID], unique: true, name: 'index_games_on_all_values_unique'
    end
end
