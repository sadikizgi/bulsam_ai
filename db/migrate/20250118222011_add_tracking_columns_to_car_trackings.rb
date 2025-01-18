class AddTrackingColumnsToCarTrackings < ActiveRecord::Migration[8.0]
  def change
    add_column :car_trackings, :daily_scrape_count, :integer
    add_column :car_trackings, :total_scrape_count, :integer
    add_column :car_trackings, :last_scrape_at, :datetime
  end
end
