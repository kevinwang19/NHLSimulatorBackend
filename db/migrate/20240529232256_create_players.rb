class CreatePlayers < ActiveRecord::Migration[7.1]
    def change
        create_table :players do |t|
            t.integer :playerID, null: false
            t.string :headshot
            t.string :firstName, null: false
            t.string :lastName, null: false
            t.integer :sweaterNumber
            t.string :positionCode, null: false
            t.string :shootsCatches, null: false
            t.integer :heightInInches, null: false
            t.integer :weightInPounds, null: false
            t.string :birthDate, null: false
            t.string :birthCountry, null: false
            t.integer :teamID, null: false
            t.boolean :isActive, default: true, null: false

            t.timestamps
        end

        add_index :players, :playerID, unique: true
    end
end
