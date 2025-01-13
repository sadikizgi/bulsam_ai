class AddDetailsToCarScrapes < ActiveRecord::Migration[8.0]
  def change
    add_column :car_scrapes, :url, :string
    add_column :car_scrapes, :image_url, :string
    add_column :car_scrapes, :images_count, :integer
    add_column :car_scrapes, :currency, :string
    add_column :car_scrapes, :public_date, :datetime
    add_column :car_scrapes, :city, :string
  end
end
