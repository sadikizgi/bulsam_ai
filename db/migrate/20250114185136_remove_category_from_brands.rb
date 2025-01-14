class RemoveCategoryFromBrands < ActiveRecord::Migration[8.0]
  def change
    remove_column :brands, :category, :string
  end
end
