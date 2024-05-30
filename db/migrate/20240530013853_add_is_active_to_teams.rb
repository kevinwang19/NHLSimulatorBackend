class AddIsActiveToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :isActive, :boolean, default: true
  end
end
