class CreateTeams < ActiveRecord::Migration[7.1]
    def change
        create_table :teams do |t|
            t.integer :teamID, null: false
            t.string :fullName, null: false
            t.string :abbrev, null: false
            t.string :logo, null: false

            t.timestamps
        end

        add_index :teams, :teamID, unique: true
    end
end
