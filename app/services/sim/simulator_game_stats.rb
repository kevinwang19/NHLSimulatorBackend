module Sim
    class SimulatorGameStats
        # Save game simulated scores to database
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

        # Save playoff game simulated scores to database
        def save_playoff_game_stats(playoff_schedule_id, away_team_score, home_team_score)
            # Find the playoff game in the playoff schedule
            playoff_schedule = PlayoffSchedule.find_by(playoffScheduleID: playoff_schedule_id)

            # Update schedule scores
            if playoff_schedule
                playoff_schedule.update(
                    awayTeamScore: away_team_score,
                    homeTeamScore: home_team_score
                )
            end
        end
    end
end