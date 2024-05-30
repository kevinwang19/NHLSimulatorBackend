class Team < ApplicationRecord
    # Validation rules
    validates :teamID, presence: true, uniqueness: true
    validates :fullName, presence: true
    validates :abbrev, presence: true
    validates :logo, presence: true

    # Associations
    has_many :home_games, class_name: 'Schedule', foreign_key: 'homeTeamID'
    has_many :away_games, class_name: 'Schedule', foreign_key: 'awayTeamID'
    has_many :players, foreign_key: 'teamID', dependent: :destroy
end