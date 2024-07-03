class CreateUsers < ActiveRecord::Migration[7.1]
    def change
        create_table :users, id: false  do |t|
            t.primary_key :userID
            t.string :username, null: false
            t.integer :favTeamID

            t.timestamps
        end

        add_foreign_key :users, :teams, column: :favTeamID, primary_key: :teamID
    end
end
