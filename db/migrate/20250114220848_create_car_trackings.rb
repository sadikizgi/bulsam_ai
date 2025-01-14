class CreateCarTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :car_trackings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :brand, null: false, foreign_key: true
      t.references :model, null: false, foreign_key: true
      t.references :serial, null: false, foreign_key: true
      t.text :websites
      t.text :cities

      t.timestamps
    end
  end
end
