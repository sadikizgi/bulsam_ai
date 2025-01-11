class CreateScrapIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :scrap_issues do |t|
      t.string :url, null: false
      t.text :error_message, null: false
      t.references :sprint, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :scrap_issues, :url
  end
end
