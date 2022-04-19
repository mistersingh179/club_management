# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20220419142957) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "checkins", force: :cascade do |t|
    t.bigint "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "paid", default: false
    t.integer "amount_collected", default: 0
    t.index ["member_id"], name: "index_checkins_on_member_id"
  end

  create_table "clubs", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner_id"
    t.string "keyword"
    t.string "simply_compete_username"
    t.string "simply_compete_password"
    t.string "simply_compete_league_id"
    t.integer "default_amount_to_collect", default: 10
    t.index ["owner_id"], name: "index_clubs_on_owner_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.bigint "club_id"
    t.string "phone_number"
    t.boolean "full_time", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "qr_code_number"
    t.integer "league_rating", default: 0
    t.integer "usatt_number"
    t.integer "table_number"
    t.string "membership_kind", default: "part_time"
    t.text "notes"
    t.date "usatt_expiration"
    t.index ["club_id"], name: "index_members_on_club_id"
  end

  create_table "owners", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.json "tokens"
    t.index ["email"], name: "index_owners_on_email", unique: true
    t.index ["reset_password_token"], name: "index_owners_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_owners_on_uid_and_provider", unique: true
  end

  create_table "play_dates", force: :cascade do |t|
    t.date "the_date"
    t.integer "club_id"
    t.string "title"
    t.index ["club_id"], name: "index_play_dates_on_club_id"
  end

  add_foreign_key "checkins", "members"
  add_foreign_key "clubs", "owners"
  add_foreign_key "members", "clubs"
end
