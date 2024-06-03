class GoalieStat < ApplicationRecord
    # Validation rules
    validates :playerID, presence: true
    validates :season, presence: true
    validates :gamesPlayed, presence: true
    validates :gamesStarted, presence: true
    validates :wins, presence: true
    validates :losses, presence: true
    validates :otLosses, presence: true
    validates :goalsAgainst, presence: true
    validates :goalsAgainstAvg, presence: true
    validates :savePctg, presence: true
    validates :shotsAgainst, presence: true
    validates :shutouts, presence: true

    # Associations
    belongs_to :player, foreign_key: "playerID"
end