namespace :app do
        desc "Simulates games in the season"
        task simulate_season: :environment do
            game_simulator = GameSimulator.new

            current_season = Schedule.maximum(:season)
            current_season_games = Schedule.where(season: current_season)
            grouped_date_games = current_season_games.group_by { |games| games.date }

            teams = {
                "test" => 0
            }
            players = {
                "test" => 0
            }

            grouped_date_games.each do |_, games|
                game_simulator.simulate_games(games, teams, players)
            end

            teams.keys.sort.each do |team|
                puts "#{team}: #{teams[team]}"
            end

            players.keys.sort.each do |player|
                puts "#{player}: #{players[player]}"
            end
        end
    end