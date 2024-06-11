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

ActiveRecord::Schema[7.1].define(version: 2024_06_06_230750) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "goalie_stats", force: :cascade do |t|
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

  create_table "goalie_stats_predictions", force: :cascade do |t|
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
    t.integer "teamID", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "offensiveRating"
    t.integer "defensiveRating"
    t.index ["playerID"], name: "index_players_on_playerID", unique: true
  end

  create_table "players_backups", id: false, force: :cascade do |t|
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
    t.integer "teamID", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.string "date", null: false
    t.string "dayAbbrev", null: false
    t.integer "season", null: false
    t.integer "awayTeamID", null: false
    t.string "awayTeamAbbrev", null: false
    t.string "awayTeamLogo", null: false
    t.integer "homeTeamID", null: false
    t.string "homeTeamAbbrev", null: false
    t.string "homeTeamLogo", null: false
    t.string "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "awayTeamID", "homeTeamID"], name: "index_games_on_all_values_unique", unique: true
  end

  create_table "skater_stats", force: :cascade do |t|
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

  create_table "skater_stats_predictions", force: :cascade do |t|
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
    t.string "logo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "isActive", default: true
    t.index ["teamID"], name: "index_teams_on_teamID", unique: true
  end

  add_foreign_key "goalie_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "goalie_stats_predictions", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "players", "teams", column: "teamID", primary_key: "teamID"
  add_foreign_key "players_backups", "teams", column: "teamID", primary_key: "teamID"
  add_foreign_key "skater_stats", "players", column: "playerID", primary_key: "playerID"
  add_foreign_key "skater_stats_predictions", "players", column: "playerID", primary_key: "playerID"
end
