class UpdateSimulationStatDefaults < ActiveRecord::Migration[7.1]
    def change
        change_column :simulation_goalie_stats, :"goalsAgainstPerGame", :float, default: 0.0, null: false

        change_column :simulation_team_stats, :"goalsForPerGame", :float, default: 0.0, null: false
        change_column :simulation_team_stats, :"goalsAgainstPerGame", :float, default: 0.0, null: false
        change_column :simulation_team_stats, :"powerPlayPctg", :float, default: 0.0, null: false
        change_column :simulation_team_stats, :"penaltyKillPctg", :float, default: 0.0, null: false
    end
end
