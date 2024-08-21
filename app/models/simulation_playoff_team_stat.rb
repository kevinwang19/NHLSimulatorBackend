class SimulationPlayoffTeamStat < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :teamID, presence: true
    validates :gamesPlayed, presence: true
    validates :wins, presence: true
    validates :losses, presence: true
    validates :otLosses, presence: true
    validates :goalsFor, presence: true
    validates :goalsForPerGame, presence: true
    validates :goalsAgainst, presence: true
    validates :goalsAgainstPerGame, presence: true
    validates :totalPowerPlays, presence: true
    validates :powerPlayPctg, presence: true
    validates :totalPenaltyKills, presence: true
    validates :penaltyKillPctg, presence: true

    # Associations
    belongs_to :simulation, foreign_key: "simulationID"
    belongs_to :team, foreign_key: "teamID"
end