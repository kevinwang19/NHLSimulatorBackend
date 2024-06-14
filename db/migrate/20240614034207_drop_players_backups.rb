class DropPlayersBackups < ActiveRecord::Migration[7.1]
    def change
        drop_table :players_backups
    end
end
