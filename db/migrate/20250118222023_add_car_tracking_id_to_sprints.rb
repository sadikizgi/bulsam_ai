class AddCarTrackingIdToSprints < ActiveRecord::Migration[8.0]
  def change
    add_column :sprints, :car_tracking_id, :integer
  end
end
