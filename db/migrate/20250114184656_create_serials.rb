class CreateSerials < ActiveRecord::Migration[8.0]
  def change
    create_table :serials do |t|
      t.string :name
      t.string :engine_size
      t.references :model, null: false, foreign_key: true

      t.timestamps
    end
  end
end
