class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :property_type
      t.string :rooms
      t.integer :size
      t.string :floor
      t.integer :age
      t.decimal :price
      t.string :location
      t.text :features
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
