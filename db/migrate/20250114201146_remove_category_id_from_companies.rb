class RemoveCategoryIdFromCompanies < ActiveRecord::Migration[8.0]
  def change
    remove_reference :companies, :category, null: false, foreign_key: true
  end
end
