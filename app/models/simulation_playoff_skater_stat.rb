class SimulationPlayoffSkaterStat < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :playerID, presence: true
    validates :gamesPlayed, presence: true
    validates :goals, presence: true
    validates :assists, presence: true
    validates :points, presence: true
    validates :powerPlayGoals, presence: true
    validates :powerPlayPoints, presence: true

    # Associations
    belongs_to :simulation, foreign_key: "simulationID"
    belongs_to :player, foreign_key: "playerID"
end