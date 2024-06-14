class Player < ApplicationRecord
    self.primary_key = :playerID

    # Validation rules
    validates :playerID, presence: true
    validates :firstName, presence: true
    validates :lastName, presence: true
    validates :positionCode, presence: true
    validates :shootsCatches, presence: true
    validates :heightInInches, presence: true
    validates :weightInPounds, presence: true
    validates :birthDate, presence: true
    validates :birthCountry, presence: true

    # Associations
    belongs_to :team, foreign_key: "teamID"
    has_many :skater_stats, foreign_key: "playerID", dependent: :destroy
    has_many :goalie_stats, foreign_key: "playerID", dependent: :destroy
    has_many :skater_stats_predictions, foreign_key: "playerID", dependent: :destroy
    has_many :goalie_stats_predictions, foreign_key: "playerID", dependent: :destroy
end