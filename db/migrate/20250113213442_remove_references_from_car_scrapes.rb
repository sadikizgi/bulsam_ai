class RemoveReferencesFromCarScrapes < ActiveRecord::Migration[8.0]
  def change
    remove_reference :car_scrapes, :car, foreign_key: true
    remove_reference :car_scrapes, :category, foreign_key: true
  end
end
