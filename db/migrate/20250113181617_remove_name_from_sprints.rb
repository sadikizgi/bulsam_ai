class RemoveNameFromSprints < ActiveRecord::Migration[8.0]
  def change
    remove_column :sprints, :name, :string
  end
end
