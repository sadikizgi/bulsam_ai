class CreatePropertyTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :property_trackings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :property_type, foreign_key: true
      t.text :websites
      t.text :cities
      t.integer :daily_scrape_count, default: 0
      t.integer :total_scrape_count, default: 0
      t.datetime :last_scrape_at

      t.timestamps
    end

    add_index :property_trackings, [:user_id, :category_id, :property_type_id]
  end
end
