class AddDomainToCarScrapes < ActiveRecord::Migration[8.0]
  def change
    add_column :car_scrapes, :domain, :string
  end
end
