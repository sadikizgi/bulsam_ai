class AddNotificationFieldsToCarScrapes < ActiveRecord::Migration[7.1]
  def change
    add_column :car_scrapes, :notification_sent, :boolean, default: false
    add_column :car_scrapes, :notification_sent_at, :datetime
    add_index :car_scrapes, :notification_sent
    add_index :car_scrapes, :notification_sent_at
  end
end
