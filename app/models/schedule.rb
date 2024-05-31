class Schedule < ApplicationRecord
    # Validation rules
    validates :date, presence: true
    validates :dayAbbrev, presence: true
    validates :season, presence: true
    validates :awayTeamID, presence: true
    validates :awayTeamAbbrev, presence: true
    validates :awayTeamLogo, presence: true
    validates :homeTeamID, presence: true
    validates :homeTeamAbbrev, presence: true
    validates :homeTeamLogo, presence: true
end
