class UpdateSchedulesNullConstraints < ActiveRecord::Migration[7.1]
    def change
        change_column_null :schedules, :date, false
        change_column_null :schedules, :dayAbbrev, false
        change_column_null :schedules, :season, false
        change_column_null :schedules, :awayTeamID, false
        change_column_null :schedules, :awayTeamAbbrev, false
        change_column_null :schedules, :awayTeamLogo, false
        change_column_null :schedules, :homeTeamID, false
        change_column_null :schedules, :homeTeamAbbrev, false
        change_column_null :schedules, :homeTeamLogo, false
    end
end
