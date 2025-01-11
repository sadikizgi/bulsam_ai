class CreateSprints < ActiveRecord::Migration[8.0]
  def change
    create_table :sprints do |t|
      t.references :company, null: false, foreign_key: true
      t.string :domain
      t.integer :total_items
      t.string :sidekiq_name
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
