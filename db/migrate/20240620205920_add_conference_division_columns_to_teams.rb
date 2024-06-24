class AddConferenceDivisionColumnsToTeams < ActiveRecord::Migration[7.1]
    def change
        add_column :teams, :conference, :string
        add_column :teams, :division, :string
    end
end
