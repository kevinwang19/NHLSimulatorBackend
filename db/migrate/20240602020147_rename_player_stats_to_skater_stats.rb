class RenamePlayerStatsToSkaterStats < ActiveRecord::Migration[7.1]
    def change
        rename_table :player_stats, :skater_stats
    end
end
