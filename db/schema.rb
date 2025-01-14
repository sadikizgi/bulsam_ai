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

ActiveRecord::Schema[8.0].define(version: 2025_01_14_202820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.decimal "price", precision: 15, scale: 2
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
    t.index ["sprint_id"], name: "index_car_scrapes_on_sprint_id"
  end

  create_table "car_tracking_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "websites"
    t.text "cities"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_car_tracking_preferences_on_user_id"
  end

  create_table "cars", force: :cascade do |t|
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
    t.index ["vehicle_id"], name: "index_cars_on_vehicle_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.string "category_url"
    t.index ["company_id"], name: "index_categories_on_company_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "notifications", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.boolean "read"
    t.string "category"
    t.bigint "user_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
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

  create_table "property_filters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price_min"
    t.decimal "price_max"
    t.string "room_count"
    t.string "building_age"
    t.string "heating_type"
    t.string "location"
    t.string "notification_frequency"
    t.boolean "is_active"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_property_filters_on_user_id"
  end

  create_table "property_filters_tracking_sources", id: false, force: :cascade do |t|
    t.bigint "property_filter_id", null: false
    t.bigint "tracking_source_id", null: false
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
    t.index ["company_id"], name: "index_sprints_on_company_id"
  end

  create_table "tracking_sources", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "base_url"
    t.jsonb "scraping_rules"
    t.integer "request_interval"
    t.datetime "last_scraped_at"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tracking_sources_vehicle_filters", id: false, force: :cascade do |t|
    t.bigint "vehicle_filter_id", null: false
    t.bigint "tracking_source_id", null: false
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
    t.boolean "email_notifications"
    t.boolean "browser_notifications"
    t.boolean "daily_digest"
    t.boolean "weekly_report"
    t.boolean "save_search_history"
    t.boolean "save_view_history"
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicle_filters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price_min"
    t.decimal "price_max"
    t.integer "year_min"
    t.integer "year_max"
    t.integer "mileage_min"
    t.integer "mileage_max"
    t.string "fuel_type"
    t.string "transmission"
    t.string "location"
    t.string "notification_frequency"
    t.boolean "is_active"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vehicle_filters_on_user_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_vehicles_on_company_id"
  end

  create_table "websites", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brands", "categories"
  add_foreign_key "car_scrapes", "sprints"
  add_foreign_key "car_tracking_preferences", "users"
  add_foreign_key "cars", "vehicles"
  add_foreign_key "categories", "companies"
  add_foreign_key "models", "brands"
  add_foreign_key "notifications", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_filters", "users"
  add_foreign_key "property_scrapes", "categories"
  add_foreign_key "property_scrapes", "properties"
  add_foreign_key "property_scrapes", "sprints"
  add_foreign_key "scrap_issues", "sprints"
  add_foreign_key "serials", "models"
  add_foreign_key "sprints", "companies"
  add_foreign_key "vehicle_filters", "users"
  add_foreign_key "vehicles", "companies"
end
