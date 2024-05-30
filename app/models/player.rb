class Player < ApplicationRecord
    # Validation rules
    validates :playerID, presence: true, uniqueness: true
    validates :firstName, presence: true
    validates :lastName, presence: true
    validates :positionCode, presence: true
    validates :shootsCatches, presence: true
    validates :heightInInches, presence: true
    validates :weightInPounds, presence: true
    validates :birthDate, presence: true
    validates :birthCountry, presence: true
    validates :teamID, presence: true
    validates :isActive, presence: true

    # Associations
    belongs_to :team, foreign_key: 'teamID'
end