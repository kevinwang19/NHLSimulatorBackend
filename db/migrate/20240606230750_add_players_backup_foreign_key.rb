class AddPlayersBackupForeignKey < ActiveRecord::Migration[7.1]
    def change
        add_foreign_key :players_backups, :teams, column: :teamID, primary_key: :teamID
    end
end
