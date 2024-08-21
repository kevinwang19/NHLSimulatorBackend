class PlayoffSchedule < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :date, presence: true
    validates :awayTeamID, presence: true
    validates :awayTeamAbbrev, presence: true
    validates :awayTeamLogo, presence: true
    validates :homeTeamID, presence: true
    validates :homeTeamAbbrev, presence: true
    validates :homeTeamLogo, presence: true

    # Associations
    belongs_to :simulation, foreign_key: "simulationID"
    belongs_to :team, foreign_key: "awayTeamID"
    belongs_to :team, foreign_key: "homeTeamID"
end