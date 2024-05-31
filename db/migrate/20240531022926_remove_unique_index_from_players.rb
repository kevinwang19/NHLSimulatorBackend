class RemoveUniqueIndexFromPlayers < ActiveRecord::Migration[7.1]
    def change
        remove_index :players, column: :playerID, name: 'index_players_on_playerID'
    end
end
