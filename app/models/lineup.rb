class Lineup < ApplicationRecord
    # Validation rules
    validates :playerID, presence: true
    validates :position, presence: true

    # Associations
    belongs_to :player, foreign_key: "playerID"
    belongs_to :team, foreign_key: "teamID", optional: true
end