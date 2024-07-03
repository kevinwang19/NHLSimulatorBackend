class Team < ApplicationRecord
    self.primary_key = :teamID

    # Validation rules
    validates :teamID, presence: true, uniqueness: true
    validates :fullName, presence: true
    validates :abbrev, presence: true

    # Associations
    has_many :schedules, foreign_key: "homeTeamID", dependent: :nullify
    has_many :schedules, foreign_key: "awayTeamID", dependent: :nullify
    has_many :players, foreign_key: "teamID", dependent: :nullify
    has_many :users, foreign_key: "favTeamID", dependent: :nullify
    has_many :simulation_team_stats, foreign_key: "teamID", dependent: :destroy
end