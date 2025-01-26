class CreatePropertyScrapes < ActiveRecord::Migration[8.0]
  def change
    create_table :property_scrapes do |t|
      t.references :sprint, null: false, foreign_key: true
      t.string :title
      t.decimal :price
      t.integer :size
      t.string :room_count
      t.integer :floor
      t.string :city
      t.string :image_url
      t.string :product_url
      t.datetime :public_date
      t.boolean :is_new, default: true
      t.boolean :is_replay, default: false
      t.datetime :add_date
      t.string :external_id

      t.timestamps
    end

    add_index :property_scrapes, [:product_url, :sprint_id], unique: true
    add_index :property_scrapes, :external_id
  end
end
