# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_06_24_221347) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "goalie_stats", primary_key: "goalieStatID", id: :bigint, default: -> { "nextval('goalie_stats_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "playerID", null: false
    t.integer "season", null: false
    t.integer "gamesPlayed", null: false
    t.integer "gamesStarted", null: false
    t.integer "wins", null: false
    t.integer "losses", null: false
    t.integer "otLosses", null: false
    t.integer "goalsAgainst", null: false
    t.decimal "goalsAgainstAvg", null: false
    t.decimal "savePctg", null: false
    t.integer "shotsAgainst", null: false
    t.integer "shutouts", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "goalie_stats_predictions", primary_key: "goaliePredictedStatID", id: :bigint, default: -> { "nextval('goalie_stats_predictions_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "playerID", null: false
    t.integer "gamesPlayed", null: false
    t.integer "gamesStarted", null: false
    t.integer "wins", null: false
    t.integer "losses", null: false
    t.integer "otLosses", null: false
    t.integer "goalsAgainst", null: false
    t.decimal "goalsAgainstAvg", null: false
    t.decimal "savePctg", null: false
    t.integer "shotsAgainst", null: false
    t.integer "shutouts", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lineups", primary_key: "lineupID", id: :bigint, default: -> { "nextval('lineups_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "playerID", null: false
    t.integer "teamID"
    t.string "position", null: false
    t.integer "lineNumber"
    t.integer "powerPlayLineNumber"
    t.integer "penaltyKillLineNumber"
    t.integer "otLineNumber"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", id: false, force: :cascade do |t|
    t.integer "playerID", null: false
    t.string "headshot"
    t.string "firstName", null: false
    t.string "lastName", null: false
    t.integer "sweaterNumber"
    t.string "positionCode", null: false
    t.string "shootsCatches", null: false
    t.integer "heightInInches", null: false
    t.integer "weightInPounds", null: false
    t.string "birthDate", null: false
    t.string "birthCountry", null: false
    t.integer "teamID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "offensiveRating"
    t.integer "defensiveRating"
    t.index ["playerID"], name: "index_players_on_playerID", unique: true
  end

  create_table "schedules", primary_key: "scheduleID", id: :bigint, default: -> { "nextval('schedules_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "date", null: false
    t.string "dayAbbrev", null: false
    t.integer "season", null: false
    t.integer "awayTeamID", null: false
    t.string "awayTeamAbbrev", null: false
    t.string "awayTeamLogo", null: false
    t.integer "homeTeamID", null: false
    t.string "homeTeamAbbrev", null: false
    t.string "homeTeamLogo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "awayTeamID", "homeTeamID"], name: "index_games_on_all_values_unique", unique: true
  end

  create_table "simulation_game_stats", primary_key: "simulationGameStatID", force: :cascade do |t|
    t.integer "simulationID", null: false
    t.integer "scheduleID"
    t.integer "awayTeamID", null: false
    t.integer "awayTeamScore", null: false
    t.integer "homeTeamID", null: false
    t.integer "homeTeamScore", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simulation_goalie_stats", primary_key: "simulationGoalieStatID", force: :cascade do |t|
    t.integer "simulationID", null: false
    t.integer "playerID", null: false
    t.integer "gamesPlayed", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "otLosses", default: 0, null: false
    t.decimal "goalsAgainstPerGame", default: "0.0", null: false
    t.integer "shutouts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simulation_skater_stats", primary_key: "simulationSkaterStatID", force: :cascade do |t|
    t.integer "simulationID", null: false
    t.integer "playerID", null: false
    t.integer "gamesPlayed", default: 0, null: false
    t.integer "goals", default: 0, null: false
    t.integer "assists", default: 0, null: false
    t.integer "points", default: 0, null: false
    t.integer "powerPlayGoals", default: 0, null: false
    t.integer "powerPlayPoints", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simulation_team_stats", primary_key: "simulationTeamStatID", force: :cascade do |t|
    t.integer "simulationID", null: false
    t.integer "teamID", null: false
    t.integer "gamesPlayed", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "otLosses", default: 0, null: false
    t.integer "points", default: 0, null: false
    t.integer "goalsFor", default: 0, null: false
    t.decimal "goalsForPerGame", default: "0.0", null: false
    t.integer "goalsAgainst", default: 0, null: false
    t.decimal "goalsAgainstPerGame", default: "0.0", null: false
    t.integer "totalPowerPlays", default: 0, null: false
    t.decimal "powerPlayPctg", default: "0.0", null: false
    t.integer "totalPenaltyKills", default: 0, null: false
    t.decimal "penaltyKillPctg", default: "0.0", null: false
    t.integer "divisionRank"
    t.integer "conferenceRank"
    t.integer "leagueRank"
    t.boolean "isWildCard"
    t.boolean "isPresidents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simulations", primary_key: "simulationID", force: :cascade do |t|
    t.integer "userID", null: false
    t.integer "season", null: false
    t.string "status", null: false
    t.string "simulationCurrentDate", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skater_stats", primary_key: "skaterStatID", id: :bigint, default: -> { "nextval('skater_stats_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "playerID", null: false
    t.integer "season", null: false
    t.integer "gamesPlayed", null: false
    t.integer "goals", null: false
    t.integer "assists", null: false
    t.integer "points", null: false
    t.string "avgToi", null: false
    t.decimal "faceoffWinningPctg", null: false
    t.integer "gameWinningGoals", null: false
    t.integer "otGoals", null: false
    t.integer "pim", null: false
    t.integer "plusMinus", null: false
    t.integer "powerPlayGoals", null: false
    t.integer "powerPlayPoints", null: false
    t.decimal "shootingPctg", null: false
    t.integer "shorthandedGoals", null: false
    t.integer "shorthandedPoints", null: false
    t.integer "shots", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skater_stats_predictions", primary_key: "skaterPredictedStatID", id: :bigint, default: -> { "nextval('skater_stats_predictions_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "playerID", null: false
    t.integer "gamesPlayed", null: false
    t.integer "goals", null: false
    t.integer "assists", null: false
    t.integer "points", null: false
    t.decimal "avgToi", null: false
    t.decimal "faceoffWinningPctg", null: false
    t.integer "gameWinningGoals", null: false
    t.integer "otGoals", null: false
    t.integer "pim", null: false
    t.integer "plusMinus", null: false
    t.integer "powerPlayGoals", null: false
    t.integer "powerPlayPoints", null: false
    t.decimal "shootingPctg", null: false
    t.integer "shorthandedGoals", null: false
    t.integer "shorthandedPoints", null: false
    t.integer "shots", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", id: false, force: :cascade do |t|
    t.integer "teamID", null: false
    t.string "fullName", null: false
    t.string "abbrev", null: false
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "isActive", default: true
    t.string "conference"
    t.string "division"
    t.index ["teamID"], name: "index_teams_on_teamID", unique: true
  end

  create_table "users", primary_key: "userID", force: :cascade do |t|
    t.string "username", null: false
    t.integer "favTeamID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "goalie_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "goalie_stats_predictions", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "lineups", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "lineups", "teams", column: "teamID", primary_key: "teamID"
  add_foreign_key "players", "teams", column: "teamID", primary_key: "teamID"
  add_foreign_key "simulation_game_stats", "schedules", column: "scheduleID", primary_key: "scheduleID"
  add_foreign_key "simulation_game_stats", "simulations", column: "simulationID", primary_key: "simulationID"
  add_foreign_key "simulation_goalie_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "simulation_goalie_stats", "simulations", column: "simulationID", primary_key: "simulationID"
  add_foreign_key "simulation_skater_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "simulation_skater_stats", "simulations", column: "simulationID", primary_key: "simulationID"
  add_foreign_key "simulation_team_stats", "simulations", column: "simulationID", primary_key: "simulationID"
  add_foreign_key "simulation_team_stats", "teams", column: "teamID", primary_key: "teamID"
  add_foreign_key "simulations", "users", column: "userID", primary_key: "userID"
  add_foreign_key "skater_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "skater_stats_predictions", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "users", "teams", column: "favTeamID", primary_key: "teamID"
end
