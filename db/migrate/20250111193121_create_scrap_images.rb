class CreateScrapImages < ActiveRecord::Migration[8.0]
  def change
    create_table :scrap_images do |t|
      t.string :original_url, null: false
      t.string :local_path
      t.references :scrape, polymorphic: true, null: false
      
      t.timestamps
    end
    
    add_index :scrap_images, :original_url
  end
end
