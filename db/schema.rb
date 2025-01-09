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

ActiveRecord::Schema[8.0].define(version: 2025_01_09_184216) do
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

  create_table "cars", force: :cascade do |t|
    t.string "brand"
    t.string "model"
    t.integer "year"
    t.decimal "price"
    t.integer "mileage"
    t.string "fuel_type"
    t.string "transmission"
    t.string "location"
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cars_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cars", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_filters", "users"
  add_foreign_key "vehicle_filters", "users"
end
