class AddNameToSprints < ActiveRecord::Migration[8.0]
  def change
    add_column :sprints, :name, :string
  end
end
