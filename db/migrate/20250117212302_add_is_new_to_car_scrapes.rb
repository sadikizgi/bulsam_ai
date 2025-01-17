class AddIsNewToCarScrapes < ActiveRecord::Migration[7.0]
  def change
    add_column :car_scrapes, :is_new, :boolean, default: false
  end
end
