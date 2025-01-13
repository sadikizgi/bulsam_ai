class RemoveStartedAtFromSprints < ActiveRecord::Migration[8.0]
  def change
    remove_column :sprints, :started_at, :datetime
  end
end
