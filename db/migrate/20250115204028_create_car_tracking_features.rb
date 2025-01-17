class CreateCarTrackingFeatures < ActiveRecord::Migration[7.0]
  def change
    create_table :car_tracking_features do |t|
      t.references :car_tracking, null: false, foreign_key: true
      t.string :colors
      t.integer :kilometer_min
      t.integer :kilometer_max
      t.integer :price_min
      t.integer :price_max
      t.integer :year_min
      t.integer :year_max

      t.timestamps
    end
  end
end
