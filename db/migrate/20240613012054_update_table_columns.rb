class UpdateTableColumns < ActiveRecord::Migration[7.1]
    def change
        rename_column :schedules, :id, :scheduleID
        remove_column :schedules, :score

        change_column_null :players, :teamID, true

        rename_column :skater_stats, :id, :skaterStatID

        rename_column :goalie_stats, :id, :goalieStatID

        rename_column :skater_stats_predictions, :id, :skaterPredictedStatID

        rename_column :goalie_stats_predictions, :id, :goaliePredictedStatID

        rename_column :lineups, :id, :lineupID
        change_column_null :lineups, :teamID, true
    end
end
