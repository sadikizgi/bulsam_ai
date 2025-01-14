class AddUrlToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :category_url, :string
  end
end
