class SkaterStatsController < ApplicationController
    # GET /skater_stats/skater_career_stats?playerID=:playerID
    def skater_career_stats
        @stats = SkaterStat.where(playerID: params[:playerID])
        if @stats
            serialized_stats = @stats.map do |stat|
                {
                    playerID: stat.playerID,
                    season: stat.season,
                    gamesPlayed: stat.gamesPlayed,
                    goals: stat.goals,
                    assists: stat.assists,
                    points: stat.points,
                    avgToi: stat.avgToi,
                    faceoffWinningPctg: stat.faceoffWinningPctg.to_f,
                    gameWinningGoals: stat.gameWinningGoals,
                    otGoals: stat.otGoals,
                    pim: stat.pim,
                    plusMinus: stat.plusMinus,
                    powerPlayGoals: stat.powerPlayGoals,
                    powerPlayPoints: stat.powerPlayPoints,
                    shootingPctg: stat.shootingPctg.to_f,
                    shorthandedGoals: stat.shorthandedGoals,
                    shorthandedPoints: stat.shorthandedPoints,
                    shots: stat.shots
                }
            end
            render json: { skaterStats: serialized_stats }
        else
            render json: { error: "Skater career stats not found" }, status: :not_found
        end
    end
end