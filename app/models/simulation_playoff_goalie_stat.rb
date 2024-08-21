class SimulationPlayoffGoalieStat < ApplicationRecord
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
end