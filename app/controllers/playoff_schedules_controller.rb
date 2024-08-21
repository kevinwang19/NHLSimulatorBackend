class PlayoffSchedulesController < ApplicationController
    # POST /playoff_schedules/create_round_1_playoff_schedules?simulationID=:simulationID&lineups=:lineups
    def create_round_1_playoff_schedules
        simulation = Simulation.find_by(simulationID: params[:simulationID])
        current_date = simulation.simulationCurrentDate if simulation.present?

        playoff_teams = SimulationTeamStat.joins(:team)
                            .where(simulationID: params[:simulationID])
                            .where("\"divisionRank\" IN (?) OR \"isWildCard\" = ?", [1, 2, 3], true)
                            .order("\"teams\".\"conference\", \"divisionRank\", points DESC")
        playoff_team_ids = playoff_teams.pluck(:teamID)

        playoff_lineups =  params[:lineups].select { |player| playoff_team_ids.include?(player["teamID"]) }
        
        playoff_schedules = []
        top_team_home_games = [1, 2, 5, 7]
        playoff_tree_top_divisions = ["Atlantic", "Central"]

        playoff_teams.group_by { |team_stat| team_stat.team.division }.each do |division, teams|
            # Determine division matchups
            rank_2_team = teams.find { |team| team.divisionRank == 2 }
            rank_3_team = teams.find { |team| team.divisionRank == 3 }
        
            matchup = [[rank_2_team, rank_3_team]]
        
            matchup.each do |(team1, team2)|
                game_start_date = Date.parse(current_date) + 2.days
        
                # Create a playoff schedule for the series (e.g., best-of-7 games)
                (1..7).each do |game_number|
                    home_team, away_team = top_team_home_games.include?(game_number) ? [team1, team2] : [team2, team1]
                    
                    playoff_schedule = PlayoffSchedule.create(
                        simulationID: params[:simulationID],
                        date: (game_start_date + (game_number - 1) * 2.days).strftime("%Y-%m-%d"),
                        awayTeamID: away_team.teamID,
                        awayTeamAbbrev: away_team.team.abbrev,
                        awayTeamLogo: away_team.team.logo,
                        homeTeamID: home_team.teamID,
                        homeTeamAbbrev: home_team.team.abbrev,
                        homeTeamLogo: home_team.team.logo,
                        roundNumber: 1,
                        conference: home_team.team.conference,
                        matchupNumber: playoff_tree_top_divisions.include?(division) ? 2 : 4
                    )

                    playoff_schedules << playoff_schedule
                end
            end
        end
        
        playoff_teams.group_by { |team_stat| team_stat.team.conference }.each do |conference, teams|
            # Separate wildcard teams and rank 1 teams
            wildcard_teams = teams.select { |team| team.isWildCard }.sort_by(&:points)
            rank_1_teams = teams.select { |team| team.divisionRank == 1 }
        
            # Ensure there are exactly two wildcard teams and two rank 1 teams
            if wildcard_teams.size == 2 && rank_1_teams.size == 2
                # Determine matchups
                highest_rank_1_team = rank_1_teams.max_by(&:points)
                lowest_wildcard = wildcard_teams.first
                other_rank_1_team = rank_1_teams.reject { |team| team == highest_rank_1_team }.first
                other_wildcard = wildcard_teams.last
        
                matchups = [
                    [highest_rank_1_team, lowest_wildcard],
                    [other_rank_1_team, other_wildcard]
                ]
        
                matchups.each do |(team1, team2)|
                    game_start_date = Date.parse(current_date) + 3.days
        
                    # Create a playoff schedule for the series (e.g., best-of-7 games)
                    (1..7).each do |game_number|
                        home_team, away_team = top_team_home_games.include?(game_number) ? [team1, team2] : [team2, team1]
                        
                        playoff_schedule = PlayoffSchedule.create(
                            simulationID: params[:simulationID],
                            date: (game_start_date + (game_number - 1) * 2.days).strftime("%Y-%m-%d"),
                            awayTeamID: away_team.teamID,
                            awayTeamAbbrev: away_team.team.abbrev,
                            awayTeamLogo: away_team.team.logo,
                            homeTeamID: home_team.teamID,
                            homeTeamAbbrev: home_team.team.abbrev,
                            homeTeamLogo: home_team.team.logo,
                            roundNumber: 1,
                            conference: conference,
                            matchupNumber: playoff_tree_top_divisions.include?(team1.team.division) ? 1 : 3
                        )

                        playoff_schedules << playoff_schedule
                    end
                end
            else
              # Handle the case where there are not exactly two wildcard teams or two rank 1 teams
              Rails.logger.error("Unexpected number of wildcard teams or rank 1 teams in conference #{conference}.")
            end
        end

        errors = []

        skater_playoff_stats_errors = SimulationPlayoffSkaterStatsController.initialize_simulation_playoff_skater_stats(params[:simulationID], playoff_lineups)
        errors.concat(skater_playoff_stats_errors)

        goalie_playoff_stats_errors = SimulationPlayoffGoalieStatsController.initialize_simulation_playoff_goalie_stats(params[:simulationID], playoff_lineups)
        errors.concat(goalie_playoff_stats_errors)

        playoff_team_stats_errors = SimulationPlayoffTeamStatsController.initialize_simulation_playoff_team_stats(params[:simulationID])
        errors.concat(playoff_team_stats_errors)

        if errors.empty?
            render json: { playoffSchedules: playoff_schedules }, status: :created
        else
            render json: { errors: errors }, status: :unprocessable_entity
        end
    end

    # GET /playoff_schedules/last_round_1_playoff_schedule?simulationID=:simulationID
    def last_round_1_playoff_schedule
        @playoff_schedule = PlayoffSchedule.where(simulationID: params[:simulationID], roundNumber: 1).order(date: :desc).first
  
        if @playoff_schedule
            render json: @playoff_schedule
        else
            render json: { 
                simulationID: 0,
                date: "",
                awayTeamID: 0,
                awayTeamAbbrev: "",
                awayTeamLogo: "",
                homeTeamID: 0,
                homeTeamAbbrev: "",
                homeTeamLogo: "",
                roundNumber: 0,
                conference: "",
                matchupNumber: 0
            }
        end
    end

    # POST /playoff_schedules/create_round_2_playoff_schedules?simulationID=:simulationID
    def create_round_2_playoff_schedules
        simulation = Simulation.find_by(simulationID: params[:simulationID])
        current_date = simulation.simulationCurrentDate if simulation.present?

        round_2_teams = PlayoffSchedule.select("DISTINCT ON (simulation_playoff_team_stats.\"teamID\", playoff_schedules.\"conference\") playoff_schedules.*, simulation_playoff_team_stats.*")
            .joins("INNER JOIN simulation_playoff_team_stats ON simulation_playoff_team_stats.\"simulationID\" = playoff_schedules.\"simulationID\" AND (simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"awayTeamID\" OR simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"homeTeamID\")")
            .where(playoff_schedules: { simulationID: params[:simulationID], roundNumber: 1 })
            .where("simulation_playoff_team_stats.wins = ?", 4)
        
        playoff_schedules = []
        top_team_home_games = [1, 2, 5, 7]
        playoff_tree_top_divisions = ["Atlantic", "Central"]

        round_2_teams.group_by { |team_stat| team_stat.conference}.each do |conference, teams|
            # Determine division matchups
            conference_advancing_team_1 = teams.find { |team| team.matchupNumber == 1 }
            conference_advancing_team_2 = teams.find { |team| team.matchupNumber == 2 }
            conference_advancing_team_3 = teams.find { |team| team.matchupNumber == 3 }
            conference_advancing_team_4 = teams.find { |team| team.matchupNumber == 4 }

            conference_advancing_team_1_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_1.teamID)
            conference_advancing_team_2_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_2.teamID)
            conference_advancing_team_3_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_3.teamID)
            conference_advancing_team_4_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_4.teamID)
        
            if conference_advancing_team_1_stat && conference_advancing_team_2_stat && conference_advancing_team_3_stat && conference_advancing_team_4_stat
                conference_advancing_team_1_rank = conference_advancing_team_1_stat.leagueRank
                conference_advancing_team_2_rank = conference_advancing_team_2_stat.leagueRank
                conference_advancing_team_3_rank = conference_advancing_team_3_stat.leagueRank
                conference_advancing_team_4_rank = conference_advancing_team_4_stat.leagueRank
                
                matchup_1 = conference_advancing_team_1_stat.isWildCard ? [conference_advancing_team_2, conference_advancing_team_1] : 
                    (conference_advancing_team_1_rank < conference_advancing_team_2_rank ? [conference_advancing_team_1, conference_advancing_team_2] : [conference_advancing_team_2, conference_advancing_team_1])
                matchup_2 = conference_advancing_team_3_stat.isWildCard ? [conference_advancing_team_4, conference_advancing_team_3] : 
                    (conference_advancing_team_3_rank < conference_advancing_team_4_rank ? [conference_advancing_team_3, conference_advancing_team_4] : [conference_advancing_team_4, conference_advancing_team_3])
                
                matchups = [matchup_1, matchup_2]
            else
                matchups = []
            end
        
            matchups.each do |(team1, team2)|
                game_start_date = Date.parse(current_date) + 2.days
                home_team_division = Team.find_by(teamID: team1.teamID).division
        
                # Create a playoff schedule for the series (e.g., best-of-7 games)
                (1..7).each do |game_number|
                    home_team, away_team = top_team_home_games.include?(game_number) ? [team1, team2] : [team2, team1]
                    
                    playoff_schedule = PlayoffSchedule.create(
                        simulationID: params[:simulationID],
                        date: (game_start_date + (game_number - 1) * 2.days).strftime("%Y-%m-%d"),
                        awayTeamID: away_team.teamID,
                        awayTeamAbbrev: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamAbbrev : away_team.homeTeamAbbrev,
                        awayTeamLogo: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamLogo : away_team.homeTeamLogo,
                        homeTeamID: home_team.teamID,
                        homeTeamAbbrev: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamAbbrev : home_team.homeTeamAbbrev,
                        homeTeamLogo: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamLogo : home_team.homeTeamLogo,
                        roundNumber: 2,
                        conference: conference,
                        matchupNumber: playoff_tree_top_divisions.include?(home_team_division) ? 1 : 2
                    )

                    playoff_schedules << playoff_schedule
                end
            end
        end
        
        render json: { playoffSchedules: playoff_schedules }, status: :created
    end

    # GET /playoff_schedules/last_round_2_playoff_schedule?simulationID=:simulationID
    def last_round_2_playoff_schedule
        @playoff_schedule = PlayoffSchedule.where(simulationID: params[:simulationID], roundNumber: 2).order(date: :desc).first
  
        if @playoff_schedule
            render json: @playoff_schedule
        else
            render json: { 
                simulationID: 0,
                date: "",
                awayTeamID: 0,
                awayTeamAbbrev: "",
                awayTeamLogo: "",
                homeTeamID: 0,
                homeTeamAbbrev: "",
                homeTeamLogo: "",
                roundNumber: 0,
                conference: "",
                matchupNumber: 0
            }
        end
    end

    # POST /playoff_schedules/create_round_3_playoff_schedules?simulationID=:simulationID
    def create_round_3_playoff_schedules
        simulation = Simulation.find_by(simulationID: params[:simulationID])
        current_date = simulation.simulationCurrentDate if simulation.present?

        round_3_teams = PlayoffSchedule.select("DISTINCT ON (simulation_playoff_team_stats.\"teamID\", playoff_schedules.\"conference\") playoff_schedules.*, simulation_playoff_team_stats.*")
            .joins("INNER JOIN simulation_playoff_team_stats ON simulation_playoff_team_stats.\"simulationID\" = playoff_schedules.\"simulationID\" AND (simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"awayTeamID\" OR simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"homeTeamID\")")
            .where(playoff_schedules: { simulationID: params[:simulationID], roundNumber: 2 })
            .where("simulation_playoff_team_stats.wins = ?", 8)
        
        playoff_schedules = []
        top_team_home_games = [1, 2, 5, 7]

        round_3_teams.group_by { |team_stat| team_stat.conference}.each do |conference, teams|
            # Determine conference matchups
            conference_advancing_team_1 = teams.find { |team| team.matchupNumber == 1 }
            conference_advancing_team_2 = teams.find { |team| team.matchupNumber == 2 }
            
            conference_advancing_team_1_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_1.teamID)
            conference_advancing_team_2_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: conference_advancing_team_2.teamID)
           
            if conference_advancing_team_1_stat && conference_advancing_team_2_stat
                conference_advancing_team_1_rank = conference_advancing_team_1_stat.leagueRank
                conference_advancing_team_2_rank = conference_advancing_team_2_stat.leagueRank
                
                matchup = conference_advancing_team_1_rank < conference_advancing_team_2_rank ? [conference_advancing_team_1, conference_advancing_team_2] : [conference_advancing_team_2, conference_advancing_team_1]
                
                matchups = [matchup]
            else
                matchups = []
            end

            matchups = [matchup]
        
            matchups.each do |(team1, team2)|
                game_start_date = Date.parse(current_date) + 2.days
        
                # Create a playoff schedule for the series (e.g., best-of-7 games)
                (1..7).each do |game_number|
                    home_team, away_team = top_team_home_games.include?(game_number) ? [team1, team2] : [team2, team1]

                    playoff_schedule = PlayoffSchedule.create(
                        simulationID: params[:simulationID],
                        date: (game_start_date + (game_number - 1) * 2.days).strftime("%Y-%m-%d"),
                        awayTeamID: away_team.teamID,
                        awayTeamAbbrev: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamAbbrev : away_team.homeTeamAbbrev,
                        awayTeamLogo: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamLogo : away_team.homeTeamLogo,
                        homeTeamID: home_team.teamID,
                        homeTeamAbbrev: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamAbbrev : home_team.homeTeamAbbrev,
                        homeTeamLogo: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamLogo : home_team.homeTeamLogo,
                        roundNumber: 3,
                        conference: conference,
                        matchupNumber: 1
                    )

                    playoff_schedules << playoff_schedule
                end
            end
        end
        
        render json: { playoffSchedules: playoff_schedules }, status: :created
    end

    # GET /playoff_schedules/last_round_3_playoff_schedule?simulationID=:simulationID
    def last_round_3_playoff_schedule
        @playoff_schedule = PlayoffSchedule.where(simulationID: params[:simulationID], roundNumber: 3).order(date: :desc).first
  
        if @playoff_schedule
            render json: @playoff_schedule
        else
            render json: { 
                simulationID: 0,
                date: "",
                awayTeamID: 0,
                awayTeamAbbrev: "",
                awayTeamLogo: "",
                homeTeamID: 0,
                homeTeamAbbrev: "",
                homeTeamLogo: "",
                roundNumber: 0,
                conference: "",
                matchupNumber: 0
            }
        end
    end

    # POST /playoff_schedules/create_round_4_playoff_schedules?simulationID=:simulationID
    def create_round_4_playoff_schedules
        simulation = Simulation.find_by(simulationID: params[:simulationID])
        current_date = simulation.simulationCurrentDate if simulation.present?

        finals_teams = PlayoffSchedule.select("DISTINCT ON (simulation_playoff_team_stats.\"teamID\", playoff_schedules.\"conference\") playoff_schedules.*, simulation_playoff_team_stats.*")
            .joins("INNER JOIN simulation_playoff_team_stats ON simulation_playoff_team_stats.\"simulationID\" = playoff_schedules.\"simulationID\" AND (simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"awayTeamID\" OR simulation_playoff_team_stats.\"teamID\" = playoff_schedules.\"homeTeamID\")")
            .where(playoff_schedules: { simulationID: params[:simulationID], roundNumber: 3 })
            .where("simulation_playoff_team_stats.wins = ?", 12)
        
        playoff_schedules = []
        top_team_home_games = [1, 2, 5, 7]

        # Determine finals matchup
        finals_advancing_team_1 = finals_teams[0]
        finals_advancing_team_2 = finals_teams[1]

        finals_advancing_team_1_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: finals_advancing_team_1.teamID)
        finals_advancing_team_2_stat = SimulationTeamStat.find_by(simulationID: params[:simulationID], teamID: finals_advancing_team_2.teamID)
        
        if finals_advancing_team_1_stat && finals_advancing_team_2_stat
            finals_advancing_team_1_rank = finals_advancing_team_1_stat.leagueRank
            finals_advancing_team_2_rank = finals_advancing_team_2_stat.leagueRank
            
            matchup = finals_advancing_team_1_rank < finals_advancing_team_2_rank ? [finals_advancing_team_1, finals_advancing_team_2] : [finals_advancing_team_2, finals_advancing_team_1]
           
            matchups = [matchup]
        else
            matchups = []
        end
        
        matchups.each do |(team1, team2)|
            game_start_date = Date.parse(current_date) + 2.days
        
            # Create a playoff schedule for the series (e.g., best-of-7 games)
            (1..7).each do |game_number|
                home_team, away_team = top_team_home_games.include?(game_number) ? [team1, team2] : [team2, team1]

                playoff_schedule = PlayoffSchedule.create(
                    simulationID: params[:simulationID],
                    date: (game_start_date + (game_number - 1) * 2.days).strftime("%Y-%m-%d"),
                    awayTeamID: away_team.teamID,
                    awayTeamAbbrev: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamAbbrev : away_team.homeTeamAbbrev,
                    awayTeamLogo: away_team.teamID == away_team.awayTeamID ? away_team.awayTeamLogo : away_team.homeTeamLogo,
                    homeTeamID: home_team.teamID,
                    homeTeamAbbrev: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamAbbrev : home_team.homeTeamAbbrev,
                    homeTeamLogo: home_team.teamID == home_team.awayTeamID ? home_team.awayTeamLogo : home_team.homeTeamLogo,
                    roundNumber: 4,
                    conference: "NHL Finals",
                    matchupNumber: 1
                )

                playoff_schedules << playoff_schedule
            end
        end
        
        render json: { playoffSchedules: playoff_schedules }, status: :created
    end

    # GET /playoff_schedules/last_round_4_playoff_schedule?simulationID=:simulationID
    def last_round_4_playoff_schedule
        @playoff_schedule = PlayoffSchedule.where(simulationID: params[:simulationID], roundNumber: 4).order(date: :desc).first
  
        if @playoff_schedule
            render json: @playoff_schedule
        else
            render json: { 
                simulationID: 0,
                date: "",
                awayTeamID: 0,
                awayTeamAbbrev: "",
                awayTeamLogo: "",
                homeTeamID: 0,
                homeTeamAbbrev: "",
                homeTeamLogo: "",
                roundNumber: 0,
                conference: "",
                matchupNumber: 0
            }
        end
    end

    # DELETE /playoff_schedules/delete_extra_playoff_schedules?simulationID=:simulationID&roundNumber=:roundNumber
    def delete_extra_playoff_schedules
        if params[:roundNumber] == 1
            round_1_winners = SimulationPlayoffTeamStat.joins("LEFT JOIN \"playoff_schedules\" ON \"playoff_schedules\".\"simulationID\" = \"simulation_playoff_team_stats\".\"simulationID\" AND (\"playoff_schedules\".\"awayTeamID\" = \"simulation_playoff_team_stats\".\"teamID\" OR \"playoff_schedules\".\"homeTeamID\" = \"simulation_playoff_team_stats\".\"teamID\")")
                .where("\"simulation_playoff_team_stats\".\"simulationID\" = ? AND \"simulation_playoff_team_stats\".\"wins\" = 4 AND \"playoff_schedules\".\"roundNumber\" = 1", params[:simulationID])
                .pluck(:teamID)
            
            if round_1_winners
                PlayoffSchedule.where(simulationID: params[:simulationID])
                    .where("\"awayTeamID\" IN (?) OR \"homeTeamID\" IN (?)", round_1_winners, round_1_winners)
                    .where(awayTeamScore: nil, homeTeamScore: nil)
                    .where(roundNumber: params[:roundNumber])
                    .delete_all
            end
        elsif params[:roundNumber] == 2
            round_2_winners = SimulationPlayoffTeamStat.joins("LEFT JOIN \"playoff_schedules\" ON \"playoff_schedules\".\"awayTeamID\" = \"simulation_playoff_team_stats\".\"teamID\" OR \"playoff_schedules\".\"homeTeamID\" = \"simulation_playoff_team_stats\".\"teamID\"")
                .where("\"simulation_playoff_team_stats\".\"simulationID\" = ? AND \"simulation_playoff_team_stats\".\"wins\" = 8 AND \"playoff_schedules\".\"roundNumber\" = 2", params[:simulationID])
                .pluck(:teamID)
            
            if round_2_winners
                PlayoffSchedule.where(simulationID: params[:simulationID])
                    .where("\"awayTeamID\" IN (?) OR \"homeTeamID\" IN (?)", round_2_winners, round_2_winners)
                    .where(awayTeamScore: nil, homeTeamScore: nil)
                    .where(roundNumber: params[:roundNumber])
                    .delete_all
            end
        elsif params[:roundNumber] == 3
            round_3_winners = SimulationPlayoffTeamStat.joins("LEFT JOIN \"playoff_schedules\" ON \"playoff_schedules\".\"awayTeamID\" = \"simulation_playoff_team_stats\".\"teamID\" OR \"playoff_schedules\".\"homeTeamID\" = \"simulation_playoff_team_stats\".\"teamID\"")
                .where("\"simulation_playoff_team_stats\".\"simulationID\" = ? AND \"simulation_playoff_team_stats\".\"wins\" = 12 AND \"playoff_schedules\".\"roundNumber\" = 3", params[:simulationID])
                .pluck(:teamID)
            
            if round_3_winners
                PlayoffSchedule.where(simulationID: params[:simulationID])
                    .where("\"awayTeamID\" IN (?) OR \"homeTeamID\" IN (?)", round_3_winners, round_3_winners)
                    .where(awayTeamScore: nil, homeTeamScore: nil)
                    .where(roundNumber: params[:roundNumber])
                    .delete_all
            end
        elsif params[:roundNumber] == 4
            round_4_winners = SimulationPlayoffTeamStat.joins("LEFT JOIN \"playoff_schedules\" ON \"playoff_schedules\".\"awayTeamID\" = \"simulation_playoff_team_stats\".\"teamID\" OR \"playoff_schedules\".\"homeTeamID\" = \"simulation_playoff_team_stats\".\"teamID\"")
                .where("\"simulation_playoff_team_stats\".\"simulationID\" = ? AND \"simulation_playoff_team_stats\".\"wins\" = 16 AND \"playoff_schedules\".\"roundNumber\" = 4", params[:simulationID])
                .pluck(:teamID)
            
            if round_4_winners
                PlayoffSchedule.where(simulationID: params[:simulationID])
                    .where("\"awayTeamID\" IN (?) OR \"homeTeamID\" IN (?)", round_4_winners, round_4_winners)
                    .where(awayTeamScore: nil, homeTeamScore: nil)
                    .where(roundNumber: params[:roundNumber])
                    .delete_all
            end
        end

        render json: { playoffSchedules: [] }, status: :ok
    end

    # GET /playoff_schedules/team_date_playoff_schedule?simulationID=:simulationID&teamID=:teamID&date=:date
    def team_date_playoff_schedule
        @playoff_schedule = PlayoffSchedule.find_by(
            "\"simulationID\" = :simulationID AND (\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND date = :date", 
            simulationID: params[:simulationID], 
            teamID: params[:teamID], 
            date: params[:date]
        )
  
        if @playoff_schedule
            render json: { playoffSchedules: [@playoff_schedule]}
        else
            render json: { playoffSchedules: [] }
        end
    end

    # GET /playoff_schedules/team_month_playoff_schedules?simulationID=:simulationID&teamID=:teamID&month=:month
    def team_month_playoff_schedules
        month_string = params[:month].to_s.rjust(2, "0") # Ensure the month is two digits
        @playoff_schedules = PlayoffSchedule.where(
            "(\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND SUBSTRING(date, 6, 2) = :month AND \"simulationID\" = :simulationID", 
            teamID: params[:teamID], 
            simulationID: params[:simulationID],
            month: month_string
        )
  
        if @playoff_schedules
            render json: { playoffSchedules: @playoff_schedules }
        else
            render json: { error: "Month playoff schedule not found for the team" }, status: :not_found
        end
    end

    # GET /playoff_schedules/team_simulated_playoff_game_stats?simulationID=:simulationID&currentDate=:currentDate&teamID=:teamID
    def team_simulated_playoff_game_stats
        @playoff_schedules = PlayoffSchedule.where(
            "(\"awayTeamID\" = :teamID OR \"homeTeamID\" = :teamID) AND \"simulationID\" = :simulationID AND date < :currentDate", 
            teamID: params[:teamID], 
            simulationID: params[:simulationID],
            currentDate: params[:currentDate]
        )
  
        if @playoff_schedules
            render json: { playoffSchedules: @playoff_schedules }
        else
            render json: { playoffSchedules: [] }
        end
    end
end