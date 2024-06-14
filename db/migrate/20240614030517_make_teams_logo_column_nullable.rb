class MakeTeamsLogoColumnNullable < ActiveRecord::Migration[7.1]
    def change
        change_column_null :teams, :logo, true
    end
end
