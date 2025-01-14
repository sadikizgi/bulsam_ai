class AddUrlToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :models, :model_url, :string
  end
end
