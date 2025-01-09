class CreateCars < ActiveRecord::Migration[8.0]
  def change
    create_table :cars do |t|
      t.string :brand
      t.string :model
      t.integer :year
      t.decimal :price
      t.integer :mileage
      t.string :fuel_type
      t.string :transmission
      t.string :location
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
