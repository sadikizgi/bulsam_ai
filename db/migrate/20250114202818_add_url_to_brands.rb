class AddUrlToBrands < ActiveRecord::Migration[8.0]
  def change
    add_column :brands, :brand_url, :string
  end
end
