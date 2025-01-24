class AddIsReplayToCarScrapes < ActiveRecord::Migration[7.1]
  def change
    add_column :car_scrapes, :is_replay, :boolean, default: false
    
    # Update existing records
    CarScrape.find_each do |car|
      if car.public_date.to_date != car.add_date.to_date
        car.update_column(:is_replay, true)
      end
    end
  end
end
