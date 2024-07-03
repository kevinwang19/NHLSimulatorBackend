class SimulationTeamStat < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :teamID, presence: true
    validates :gamesPlayed, presence: true
    validates :wins, presence: true
    validates :losses, presence: true
    validates :otLosses, presence: true
    validates :points, presence: true
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

    # Default values
    after_initialize :set_defaults

    def set_defaults
        self.gamesPlayed ||= 0
        self.wins ||= 0
        self.losses ||= 0
        self.otLosses ||= 0
        self.points ||= 0
        self.goalsFor ||= 0
        self.goalsForPerGame ||= 0.0
        self.goalsAgainst ||= 0
        self.goalsAgainstPerGame ||= 0.0
        self.totalPowerPlays ||= 0
        self.powerPlayPctg ||= 0.0
        self.totalPenaltyKills ||= 0
        self.penaltyKillPctg ||= 0.0
    end
end
