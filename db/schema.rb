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

ActiveRecord::Schema[7.1].define(version: 2024_05_29_232256) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "players", force: :cascade do |t|
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
    t.boolean "isActive", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playerID"], name: "index_players_on_playerID", unique: true
  end

  create_table "schedules", force: :cascade do |t|
    t.string "date"
    t.string "dayAbbrev"
    t.integer "season"
    t.integer "awayTeamID"
    t.string "awayTeamAbbrev"
    t.string "awayTeamLogo"
    t.integer "homeTeamID"
    t.string "homeTeamAbbrev"
    t.string "homeTeamLogo"
    t.string "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "awayTeamID", "homeTeamID"], name: "index_games_on_all_values_unique", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.integer "teamID", null: false
    t.string "fullName", null: false
    t.string "abbrev", null: false
    t.string "logo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teamID"], name: "index_teams_on_teamID", unique: true
  end

end
