class ChangeCarScrapesPriceToDecimal < ActiveRecord::Migration[8.0]
  def change
    change_column :car_scrapes, :price, :integer
  end
end
