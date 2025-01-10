class AddExternalIdToCarsAndProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :cars, :external_id, :string
    add_column :properties, :external_id, :string
    
    add_index :cars, :external_id, unique: true
    add_index :properties, :external_id, unique: true
  end
end
