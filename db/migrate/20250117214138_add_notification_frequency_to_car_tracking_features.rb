class AddNotificationFrequencyToCarTrackingFeatures < ActiveRecord::Migration[7.0]
  def change
    add_column :car_tracking_features, :notification_frequency, :string, default: '1h'
  end
end
