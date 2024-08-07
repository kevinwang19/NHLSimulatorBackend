module Sim
    class SimulatorTeamStats
        # Save winning team simulated stats to SimulationTeamStats database
        def save_team_stats_win(simulation_id, team_id, goals_scored, goals_allowed, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)
            # Find the current simulation team stats from the database
            team_stat = SimulationTeamStat.find_by(simulationID: simulation_id, teamID: team_id)

            if team_stat
                # Get the team special teams stats
                new_total_pps, new_pp_pctg, new_total_pks, new_pk_pctg = get_team_special_teams_stats(team_stat, pp_goals_scored, num_pps, pk_goals_allowed, num_pks)

                # Update team ranks and standings info
                update_team_standing_stats(simulation_id)

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
                    penaltyKillPctg: new_pk_pctg
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

                # Update team ranks and standings info
                update_team_standing_stats(simulation_id)

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
                    penaltyKillPctg: new_pk_pctg
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
        def update_team_standing_stats(simulation_id)
            # Get all unique divisions and conferences
            divisions = Team.distinct.pluck(:division)
            conferences = Team.distinct.pluck(:conference)

            # Update division rankings
            divisions.each do |division|
                division_team_ids = Team.where(division: division).pluck(:teamID)
                sorted_division_standings = sort_and_rank_teams(simulation_id, division_team_ids)
    
                sorted_division_standings.each_with_index do |division_team, index|
                    division_team.update(divisionRank: index + 1)
                end
            end

            # Update conference rankings
            wildcard_team_ids = []
            conferences.each do |conference|
                conference_team_ids = Team.where(conference: conference).pluck(:teamID)
                sorted_conference_standings = sort_and_rank_teams(simulation_id, conference_team_ids)
        
                sorted_conference_standings.each_with_index do |conference_team, index|
                    conference_team.update(conferenceRank: index + 1)
                end

                # Find wildcard teams for the conference
                wildcard_team_ids += find_wildcard_teams(simulation_id, conference)
            end

            # Update league rankings
            league_team_stats = SimulationTeamStat.where(simulationID: simulation_id)
            sorted_league_standings = sort_and_rank_teams(simulation_id, league_team_stats.pluck(:teamID))

            sorted_league_standings.each_with_index do |team, index|
                is_wildcard = wildcard_team_ids.include?(team.teamID)
                is_presidents = (index + 1 == 1)
                
                team.update(leagueRank: index + 1, isWildCard: is_wildcard, isPresidents: is_presidents)
            end
        end

        # Sort and rank teams
        def sort_and_rank_teams(simulation_id, team_ids)
            team_stats = SimulationTeamStat.where(simulationID: simulation_id, teamID: team_ids)

            sorted_standings = team_stats.sort_by do |team|
                [
                    -team[:points],
                    team[:gamesPlayed],
                    -team[:wins],
                ]
            end

            return sorted_standings
        end

        # Find wildcard teams for a conference
        def find_wildcard_teams(simulation_id, conference)
            wildcard_team_ids = []
            division_team_ids = {}

            # Get team IDs for each division in the conference
            Team.where(conference: conference).pluck(:division).uniq.each do |division|
                division_team_ids[division] = Team.where(division: division).pluck(:teamID)
            end

            # Get top 3 teams from each division
            top_teams_in_divisions = division_team_ids.flat_map do |division, team_ids|
                sort_and_rank_teams(simulation_id, team_ids).first(3).map(&:teamID)
            end

            # Sort remaining teams and get top 2 as wildcard teams
            remaining_team_ids = Team.where(conference: conference).pluck(:teamID) - top_teams_in_divisions
            sorted_remaining_teams = sort_and_rank_teams(simulation_id, remaining_team_ids)
            wildcard_team_ids = sorted_remaining_teams.first(2).map(&:teamID)

            return wildcard_team_ids
        end
    end
end