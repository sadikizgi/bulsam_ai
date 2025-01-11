class CreateCarScrapes < ActiveRecord::Migration[8.0]
  def change
    create_table :car_scrapes do |t|
      t.string :address
      t.string :name
      t.string :title
      t.datetime :add_date
      t.string :make
      t.string :series
      t.string :model
      t.integer :year
      t.string :fuel_type
      t.string :gear
      t.integer :km
      t.string :body_type
      t.string :enginepower
      t.string :enginecategory
      t.string :traction
      t.string :color
      t.string :warranty
      t.string :plate
      t.string :from
      t.boolean :videocall
      t.boolean :exchangeable
      t.string :condition
      t.decimal :price
      t.string :seller_name
      t.string :seller_work_tel
      t.string :seller_mobile_tel
      t.text :description
      t.string :product_url
      t.references :car, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :sprint, null: false, foreign_key: true

      t.timestamps
    end
  end
end
