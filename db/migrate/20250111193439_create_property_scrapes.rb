class CreatePropertyScrapes < ActiveRecord::Migration[8.0]
  def change
    create_table :property_scrapes do |t|
      t.string :title
      t.string :product_url
      t.decimal :price
      t.datetime :add_date
      t.references :property, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :sprint, null: false, foreign_key: true

      t.timestamps
    end

    add_index :property_scrapes, [:product_url, :sprint_id], unique: true
  end
end
