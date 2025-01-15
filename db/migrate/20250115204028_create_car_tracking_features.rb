class CreateCarTrackingFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :car_tracking_features do |t|
      t.references :car_tracking, null: false, foreign_key: true
      t.text :colors, array: true, default: []
      t.integer :kilometer_min
      t.integer :kilometer_max
      t.decimal :price_min, precision: 12, scale: 2
      t.decimal :price_max, precision: 12, scale: 2
      t.text :seller_types, array: true, default: []
      t.text :transmission_types, array: true, default: []

      t.timestamps
    end
  end
end
