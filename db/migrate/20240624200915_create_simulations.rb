class CreateSimulations < ActiveRecord::Migration[7.1]
    def change
        create_table :simulations, id: false  do |t|
            t.primary_key :simulationID
            t.integer :userID, null: false
            t.integer :season, null: false
            t.string :status, null: false
            t.string :simulationCurrentDate, null: false

            t.timestamps
        end

        add_foreign_key :simulations, :users, column: :userID, primary_key: :userID
    end
end
