class SimulationGoalieStat < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :playerID, presence: true
    validates :gamesPlayed, presence: true
    validates :wins, presence: true
    validates :losses, presence: true
    validates :otLosses, presence: true
    validates :goalsAgainstPerGame, presence: true
    validates :shutouts, presence: true

    # Associations
    belongs_to :simulation, foreign_key: "simulationID"
    belongs_to :player, foreign_key: "playerID"

    # Default values
    after_initialize :set_defaults

    def set_defaults
        self.gamesPlayed ||= 0
        self.wins ||= 0
        self.losses ||= 0
        self.otLosses ||= 0
        self.goalsAgainstPerGame ||= 0.0
        self.shutouts ||= 0
    end
end