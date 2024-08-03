module Sim
    class SimulatorGameStats
        # Save game simulated scores to SimulationGameStats database
        def save_game_stats(simulation_id, schedule_id, away_team_id, away_team_score, home_team_id, home_team_score)
            SimulationGameStat.create(
                simulationID: simulation_id,
                scheduleID: schedule_id,
                awayTeamID: away_team_id,
                awayTeamScore: away_team_score,
                homeTeamID: home_team_id,
                homeTeamScore: home_team_score
            )
        end
    end
end