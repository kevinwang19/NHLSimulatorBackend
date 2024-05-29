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
    validates :score, allow_nil: true

    # Associations
    belongs_to :away_team, class_name: 'Team', foreign_key: 'awayTeamID'
    belongs_to :home_team, class_name: 'Team', foreign_key: 'homeTeamID'
end
