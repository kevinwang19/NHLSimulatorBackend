class AddRatingsColumns < ActiveRecord::Migration[7.1]
    def change
        add_column :players, :offensiveRating, :integer
        add_column :players, :defensiveRating, :integer
    end
end
