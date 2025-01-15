class ChangeSerialIdToNullableInCarTrackings < ActiveRecord::Migration[7.1]
  def change
    change_column_null :car_trackings, :serial_id, true
  end
end 