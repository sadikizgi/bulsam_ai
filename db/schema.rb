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

ActiveRecord::Schema[8.0].define(version: 2025_01_19_112407) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.string "brand_url"
    t.index ["category_id"], name: "index_brands_on_category_id"
  end

  create_table "car_scrapes", force: :cascade do |t|
    t.string "address"
    t.string "name"
    t.string "title"
    t.datetime "add_date"
    t.string "make"
    t.string "series"
    t.string "model"
    t.integer "year"
    t.string "fuel_type"
    t.string "gear"
    t.integer "km"
    t.string "body_type"
    t.string "enginepower"
    t.string "enginecategory"
    t.string "traction"
    t.string "color"
    t.string "warranty"
    t.string "plate"
    t.string "from"
    t.boolean "videocall"
    t.boolean "exchangeable"
    t.string "condition"
    t.integer "price"
    t.string "seller_name"
    t.string "seller_work_tel"
    t.string "seller_mobile_tel"
    t.text "description"
    t.string "product_url"
    t.bigint "sprint_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "image_url"
    t.integer "images_count"
    t.string "currency"
    t.datetime "public_date"
    t.string "city"
    t.string "domain"
    t.boolean "is_new", default: false
    t.index ["sprint_id"], name: "index_car_scrapes_on_sprint_id"
  end

  create_table "car_tracking_features", force: :cascade do |t|
    t.bigint "car_tracking_id", null: false
    t.string "colors"
    t.integer "kilometer_min"
    t.integer "kilometer_max"
    t.integer "price_min"
    t.integer "price_max"
    t.integer "year_min"
    t.integer "year_max"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notification_frequency", default: "1h"
    t.index ["car_tracking_id"], name: "index_car_tracking_features_on_car_tracking_id"
  end

  create_table "car_trackings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.bigint "brand_id", null: false
    t.bigint "model_id"
    t.bigint "serial_id"
    t.text "websites"
    t.text "cities"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_scrape_count"
    t.integer "total_scrape_count"
    t.datetime "last_scrape_at"
    t.index ["brand_id"], name: "index_car_trackings_on_brand_id"
    t.index ["category_id"], name: "index_car_trackings_on_category_id"
    t.index ["model_id"], name: "index_car_trackings_on_model_id"
    t.index ["serial_id"], name: "index_car_trackings_on_serial_id"
    t.index ["user_id"], name: "index_car_trackings_on_user_id"
  end

  create_table "cars", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.string "car_model"
    t.string "car_serial"
    t.string "car_motor_serial"
    t.string "car_serial_name"
    t.string "car_url"
    t.bigint "vehicle_id", null: false
    t.index ["car_url"], name: "index_cars_on_car_url", unique: true
    t.index ["external_id"], name: "index_cars_on_external_id", unique: true
    t.index ["user_id"], name: "index_cars_on_user_id"
    t.index ["vehicle_id"], name: "index_cars_on_vehicle_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.string "category_url"
    t.integer "parent_id"
    t.index ["company_id"], name: "index_categories_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "models", force: :cascade do |t|
    t.string "name"
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "model_url"
    t.index ["brand_id"], name: "index_models_on_brand_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "property_type"
    t.string "rooms"
    t.integer "size"
    t.string "floor"
    t.integer "age"
    t.decimal "price"
    t.string "location"
    t.text "features"
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["external_id"], name: "index_properties_on_external_id", unique: true
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_scrapes", force: :cascade do |t|
    t.string "title"
    t.string "product_url"
    t.decimal "price"
    t.datetime "add_date"
    t.bigint "property_id", null: false
    t.bigint "category_id", null: false
    t.bigint "sprint_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_property_scrapes_on_category_id"
    t.index ["product_url", "sprint_id"], name: "index_property_scrapes_on_product_url_and_sprint_id", unique: true
    t.index ["property_id"], name: "index_property_scrapes_on_property_id"
    t.index ["sprint_id"], name: "index_property_scrapes_on_sprint_id"
  end

  create_table "proxies", force: :cascade do |t|
    t.string "ip", null: false
    t.integer "port", null: false
    t.string "username"
    t.string "password"
    t.string "proxy_type", null: false
    t.string "status", default: "active"
    t.datetime "last_used_at"
    t.datetime "last_check_at"
    t.integer "response_time"
    t.integer "error_count", default: 0
    t.text "notes"
    t.json "supported_sites", default: {}
    t.json "performance_metrics", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ip", "port"], name: "index_proxies_on_ip_and_port", unique: true
    t.index ["last_used_at"], name: "index_proxies_on_last_used_at"
    t.index ["proxy_type"], name: "index_proxies_on_proxy_type"
    t.index ["status"], name: "index_proxies_on_status"
  end

  create_table "scrap_images", force: :cascade do |t|
    t.string "original_url", null: false
    t.string "local_path"
    t.string "scrape_type", null: false
    t.bigint "scrape_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["original_url"], name: "index_scrap_images_on_original_url"
    t.index ["scrape_type", "scrape_id"], name: "index_scrap_images_on_scrape"
  end

  create_table "scrap_issues", force: :cascade do |t|
    t.string "url", null: false
    t.text "error_message", null: false
    t.bigint "sprint_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sprint_id"], name: "index_scrap_issues_on_sprint_id"
    t.index ["url"], name: "index_scrap_issues_on_url"
  end

  create_table "serials", force: :cascade do |t|
    t.string "name"
    t.string "engine_size"
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "serial_url"
    t.index ["model_id"], name: "index_serials_on_model_id"
  end

  create_table "sprints", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "domain"
    t.integer "total_items"
    t.string "sidekiq_name"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "car_tracking_id"
    t.index ["company_id"], name: "index_sprints_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_vehicles_on_company_id"
  end

  add_foreign_key "brands", "categories"
  add_foreign_key "car_scrapes", "sprints"
  add_foreign_key "car_tracking_features", "car_trackings"
  add_foreign_key "car_trackings", "brands"
  add_foreign_key "car_trackings", "categories"
  add_foreign_key "car_trackings", "models"
  add_foreign_key "car_trackings", "serials"
  add_foreign_key "car_trackings", "users"
  add_foreign_key "cars", "users"
  add_foreign_key "cars", "vehicles"
  add_foreign_key "categories", "companies"
  add_foreign_key "models", "brands"
  add_foreign_key "properties", "users"
  add_foreign_key "property_scrapes", "categories"
  add_foreign_key "property_scrapes", "properties"
  add_foreign_key "property_scrapes", "sprints"
  add_foreign_key "scrap_issues", "sprints"
  add_foreign_key "serials", "models"
  add_foreign_key "sprints", "companies"
  add_foreign_key "vehicles", "companies"
end
