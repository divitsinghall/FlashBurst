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

ActiveRecord::Schema[8.1].define(version: 2025_12_02_182448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "product_variant_id"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "product_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "inventory_count"
    t.string "name"
    t.datetime "updated_at", null: false
  end
end
