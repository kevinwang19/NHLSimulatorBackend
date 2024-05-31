class AddForeignKeys < ActiveRecord::Migration[7.1]
    def change
        remove_column :players, :isActive

        add_index :players, :playerID, unique: true

        add_foreign_key :goalie_stats, :players, column: :playerID, primary_key: :playerID
        add_foreign_key :player_stats, :players, column: :playerID, primary_key: :playerID
        add_foreign_key :players, :teams, column: :teamID, primary_key: :teamID
    end
end
