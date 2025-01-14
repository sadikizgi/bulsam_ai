class AddUrlToSerials < ActiveRecord::Migration[8.0]
  def change
    add_column :serials, :serial_url, :string
  end
end
