class CreateLineups < ActiveRecord::Migration[7.1]
    def change
        create_table :lineups do |t|
            t.integer :playerID, null: false
            t.integer :teamID, null: false
            t.string :position, null: false
            t.integer :lineNumber
            t.integer :powerPlayLineNumber
            t.integer :penaltyKillLineNumber
            t.integer :otLineNumber

            t.timestamps
        end

        add_foreign_key :lineups, :players, column: :playerID, primary_key: :playerID
        add_foreign_key :lineups, :teams, column: :teamID, primary_key: :teamID
    end
end
