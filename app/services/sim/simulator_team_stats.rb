module Sim
    class SimulatorTeamStats
        # Save winning team simulated stats to SimulationTeamStats database
        def save_team_stats_win(simulation_id, team_id, goals_scored, goals_allowed, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)
            # Find the current simulation team stats from the database
            team_stat = SimulationTeamStat.find_by(simulationID: simulation_id, teamID: team_id)

            if team_stat
                # Get the team special teams stats
                new_total_pps, new_pp_pctg, new_total_pks, new_pk_pctg = get_team_special_teams_stats(team_stat, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)

                # Get the team ranks and standings info
                division_rank, conference_rank, league_rank, is_wildcard, is_presidents = get_team_standing_stats(simulation_id, team_id)

                # Update winning team stats since the record exists from the initial games played addition/update
                team_stat.update(
                    gamesPlayed: team_stat.gamesPlayed + 1,
                    wins: team_stat.wins + 1,
                    points: team_stat.points + 2,
                    goalsFor: team_stat.goalsFor + goals_scored,
                    goalsForPerGame: (team_stat.goalsFor + goals_scored) / (team_stat.gamesPlayed + 1).to_f,
                    goalsAgainst: team_stat.goalsAgainst + goals_allowed,
                    goalsAgainstPerGame: (team_stat.goalsAgainst + goals_allowed) / (team_stat.gamesPlayed + 1).to_f,
                    totalPowerPlays: new_total_pps,
                    powerPlayPctg: new_pp_pctg,
                    totalPenaltyKills: new_total_pks,
                    penaltyKillPctg: new_pk_pctg,
                    divisionRank: division_rank,
                    conferenceRank: conference_rank,
                    leagueRank: league_rank,
                    isWildCard: is_wildcard,
                    isPresidents: is_presidents
                )
            end
        end

        # Save losing team simulated stats to SimulationTeamStats database
        def save_team_stats_loss(simulation_id, team_id, goals_scored, goals_allowed, pp_goals_scored, num_pps, pk_goals_allowed, num_pks, required_ot)
            # Find the current simulation team stats from the database
            team_stat = SimulationTeamStat.find_by(simulationID: simulation_id, teamID: team_id)

            if team_stat
                # Get the team special teams stats
                new_total_pps, new_pp_pctg, new_total_pks, new_pk_pctg = get_team_special_teams_stats(team_stat, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)

                # Get the team ranks and standings stats
                division_rank, conference_rank, league_rank, is_wildcard, is_presidents = get_team_standing_stats(simulation_id, team_id)

                # Update winning team stats since the record exists from the initial games played addition/update
                team_stat.update(
                    gamesPlayed: team_stat.gamesPlayed + 1,
                    losses: required_ot ? team_stat.losses : team_stat.losses + 1,
                    otLosses: required_ot ? team_stat.otLosses + 1 : team_stat.otLosses,
                    points: required_ot ? team_stat.points + 1 : team_stat.points,
                    goalsFor: team_stat.goalsFor + goals_scored,
                    goalsForPerGame: (team_stat.goalsFor + goals_scored) / (team_stat.gamesPlayed + 1).to_f,
                    goalsAgainst: team_stat.goalsAgainst + goals_allowed,
                    goalsAgainstPerGame: (team_stat.goalsAgainst + goals_allowed) / (team_stat.gamesPlayed + 1).to_f,
                    totalPowerPlays: new_total_pps,
                    powerPlayPctg: new_pp_pctg,
                    totalPenaltyKills: new_total_pks,
                    penaltyKillPctg: new_pk_pctg,
                    divisionRank: division_rank,
                    conferenceRank: conference_rank,
                    leagueRank: league_rank,
                    isWildCard: is_wildcard,
                    isPresidents: is_presidents
                )
            end
        end

        # Get the powerplay and penalty kill stats of the team
        def get_team_special_teams_stats(team_stat, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)
            # Find out the total powerplay goals and add the new amount of powerplay goals to calculate the new percentage
            total_pp_goals = team_stat.powerPlayPctg * team_stat.totalPowerPlays
            new_total_pp_goals = total_pp_goals
            new_total_pp_goals += pp_goals_scored
            new_total_pps = team_stat.totalPowerPlays + num_pps
            new_pp_pctg = new_total_pps > 0 ? (new_total_pp_goals / new_total_pps.to_f) : 0.0

            # Find out the total successful penalty kills and add the new amount of penalty kill successes to calculate the new percentage
            total_pk_successes = team_stat.penaltyKillPctg * team_stat.totalPenaltyKills
            new_total_pk_successes = total_pk_successes
            new_total_pk_successes += (num_pks - pk_goals_allowed)
            new_total_pks = team_stat.totalPenaltyKills + num_pks
            new_pk_pctg = new_total_pks > 0 ? (new_total_pk_successes / new_total_pks.to_f) : 0.0

            return [new_total_pps, new_pp_pctg, new_total_pks, new_pk_pctg]
        end

        # Get the division, conference, and league standing stats of the team
        def get_team_standing_stats(simulation_id, team_id)
            # Get the division and conference of the current team
            division = Team.find_by(teamID: team_id).division
            conference = Team.find_by(teamID: team_id).conference

            # Get all the team IDs from the current division and all the teams from the current conference
            division_team_ids = Team.where(division: division).pluck(:teamID)
            conference_team_ids = Team.where(conference: conference).pluck(:teamID)

            # Get the simulation team stats from the current division, conference, and league matching the team IDs
            division_team_stats = SimulationTeamStat.where(simulationID: simulation_id, teamID: division_team_ids)
            conference_team_stats = SimulationTeamStat.where(simulationID: simulation_id, teamID: conference_team_ids)
            league_team_stats = SimulationTeamStat.where(simulationID: simulation_id)

            # Sort the division, conference, and league based on points (descending), then by games played (ascending), then by wins (descending)
            sorted_division_standings = division_team_stats.sort_by do |division_team|
                [
                -division_team[:points],
                division_team[:gamesPlayed],
                -division_team[:wins],
                ]
            end

            sorted_conference_standings = conference_team_stats.sort_by do |conference_team|
                [
                -conference_team[:points],
                conference_team[:gamesPlayed],
                -conference_team[:wins],
                ]
            end

            sorted_league_standings = league_team_stats.sort_by do |league_team|
                [
                -league_team[:points],
                league_team[:gamesPlayed],
                -league_team[:wins],
                ]
            end

            # Find the ranks in the division, conference, and league of the current team
            division_rank = sorted_division_standings.find_index { |team| team.teamID == team_id }
            conference_rank = sorted_conference_standings.find_index { |team| team.teamID == team_id }
            league_rank = sorted_league_standings.find_index { |team| team.teamID == team_id }

            # See if the current team is a wilcard team based on if its 4th or 5th in division standings and from 4th-8th in conference standings
            potential_division_wildcard_team_ids = sorted_division_standings[3..4].map { |team| team.teamID }
            potential_conference_wildcard_team_ids = sorted_conference_standings[3..7].map { |team| team.teamID }
            is_wildcard = potential_division_wildcard_team_ids.include?(team_id) && potential_conference_wildcard_team_ids.include?(team_id)
            
            # See if the team is in first in the league
            is_presidents = (league_rank == 1)

            return [division_rank, conference_rank, league_rank, is_wildcard, is_presidents]
        end
    end
end