class AddMailFieldsToCarScrapes < ActiveRecord::Migration[8.0]
  def change
    add_column :car_scrapes, :mail_sent, :boolean, default: false
    add_column :car_scrapes, :mail_sent_at, :datetime
    add_index :car_scrapes, :mail_sent
  end
end
