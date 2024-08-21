class CreatePlayoffSchedules < ActiveRecord::Migration[7.1]
    def change
        create_table :playoff_schedules, id: false  do |t|
            t.primary_key :playoffScheduleID
            t.integer :simulationID, null: false
            t.string :date, null: false
            t.integer :awayTeamID, null: false
            t.string :awayTeamAbbrev, null: false
            t.string :awayTeamLogo, null: false
            t.integer :awayTeamScore
            t.integer :homeTeamID, null: false
            t.string :homeTeamAbbrev, null: false
            t.string :homeTeamLogo, null: false
            t.integer :homeTeamScore
            t.integer :roundNumber, null: false
            t.string :conference, null: false
            t.integer :matchupNumber, null: false

            t.timestamps
        end

        add_foreign_key :playoff_schedules, :simulations, column: :simulationID, primary_key: :simulationID
        add_foreign_key :playoff_schedules, :teams, column: :awayTeamID, primary_key: :teamID
        add_foreign_key :playoff_schedules, :teams, column: :homeTeamID, primary_key: :teamID
    end
end
