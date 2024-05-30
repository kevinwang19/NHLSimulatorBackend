namespace :app do
desc "Fetch and save initial data"
    task fetch_initial: :environment do
        day_interval = 7
        web_api_client = WebApiClient.new
        api_client = ApiClient.new

        start_date = Date.new(2023, 10, 1)
        end_date = Date.new(2024, 4, 30)
        
        # Iterate through each week of the schedule and populate Schedule database
        (start_date..end_date).step(day_interval) do |date|
            web_api_client.save_schedule_data(date.to_s)
            puts "Fetched and saved schedule for week #{date.to_s}"
        end

        # Populate Teams database after fetching the initial schedule
        api_client.save_team_data(start_date)
        puts "Fetched and saved all teams from the schedule"

        teams = Team.order(:abbrev)

        teams.each do |team|
            web_api_client.save_player_data(team)
            puts "Fetched and saved players from #{team.abbrev}"
        end
    end
end