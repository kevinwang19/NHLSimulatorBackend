class GoalieStatsController < ApplicationController
    # GET /goalie_stats/goalie_career_stats?playerID=:playerID
    def goalie_career_stats
        @stats = GoalieStat.where(playerID: params[:playerID])
        if @stats
            serialized_stats = @stats.map do |stat|
                {
                    playerID: stat.playerID,
                    season: stat.season,
                    gamesPlayed: stat.gamesPlayed,
                    gamesStarted: stat.gamesStarted,
                    wins: stat.wins,
                    losses: stat.losses,
                    otLosses: stat.otLosses,
                    goalsAgainst: stat.goalsAgainst,
                    goalsAgainstAvg: stat.goalsAgainstAvg.to_f,
                    savePctg: stat.savePctg.to_f,
                    shotsAgainst: stat.shotsAgainst,
                    shutouts: stat.shutouts
                }
            end
            render json: { goalieStats: serialized_stats }
        else
            render json: { error: "Goalie career stats not found" }, status: :not_found
        end
    end
end