class AddCompanyIdToCategories < ActiveRecord::Migration[8.0]
  def change
    add_reference :categories, :company, null: false, foreign_key: true
  end
end
