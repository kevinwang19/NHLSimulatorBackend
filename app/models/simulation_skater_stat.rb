class SimulationSkaterStat < ApplicationRecord
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

    # Default values
    after_initialize :set_defaults

    def set_defaults
        self.gamesPlayed ||= 0
        self.goals ||= 0
        self.assists ||= 0
        self.points ||= 0
        self.powerPlayGoals ||= 0
        self.powerPlayPoints ||= 0
    end
end