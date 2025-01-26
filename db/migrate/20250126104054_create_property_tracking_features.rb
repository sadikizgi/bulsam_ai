class CreatePropertyTrackingFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :property_tracking_features do |t|
      t.references :property_tracking, null: false, foreign_key: true
      t.text :room_count
      t.integer :floor_min
      t.integer :floor_max
      t.integer :size_min
      t.integer :size_max
      t.decimal :price_min, precision: 15, scale: 2
      t.decimal :price_max, precision: 15, scale: 2
      t.string :notification_frequency, default: 'instant'

      t.timestamps
    end
  end
end
