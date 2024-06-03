class SkaterStat < ApplicationRecord
    # Validation rules
    validates :playerID, presence: true
    validates :season, presence: true
    validates :gamesPlayed, presence: true
    validates :goals, presence: true
    validates :assists, presence: true
    validates :points, presence: true
    validates :avgToi, presence: true
    validates :faceoffWinningPctg, presence: true
    validates :gameWinningGoals, presence: true
    validates :otGoals, presence: true
    validates :pim, presence: true
    validates :plusMinus, presence: true
    validates :powerPlayGoals, presence: true
    validates :powerPlayPoints, presence: true
    validates :shootingPctg, presence: true
    validates :shorthandedGoals, presence: true
    validates :shorthandedPoints, presence: true
    validates :shots, presence: true

    # Associations
    belongs_to :player, foreign_key: "playerID"
end