class User < ApplicationRecord
    # Validation rules
    validates :username, presence: true

    # Associations
    belongs_to :team, foreign_key: "favTeamID", optional: true
    has_many :simulations, foreign_key: "userID", dependent: :destroy
end