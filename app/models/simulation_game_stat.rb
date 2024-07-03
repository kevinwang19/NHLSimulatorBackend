class SimulationGameStat < ApplicationRecord
    # Validation rules
    validates :simulationID, presence: true
    validates :scheduleID, presence: true
    validates :awayTeamID, presence: true
    validates :awayTeamScore, presence: true
    validates :homeTeamID, presence: true
    validates :homeTeamScore, presence: true

    # Associations
    belongs_to :simulation, foreign_key: "simulationID"
    belongs_to :schedule, foreign_key: "scheduleID"
end