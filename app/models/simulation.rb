class Simulation < ApplicationRecord
    # Validation rules
    validates :userID, presence: true
    validates :season, presence: true
    validates :status, presence: true
    validates :simulationCurrentDate, presence: true

    # Associations
    belongs_to :user, foreign_key: "userID"
    has_many :simulation_skater_stats, foreign_key: "simulationID", dependent: :destroy
    has_many :simulation_goalie_stats, foreign_key: "simulationID", dependent: :destroy
    has_many :simulation_team_stats, foreign_key: "simulationID", dependent: :destroy
end