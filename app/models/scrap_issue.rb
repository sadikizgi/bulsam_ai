class ScrapIssue < ApplicationRecord
  belongs_to :sprint
  
  validates :url, presence: true
  validates :error_message, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_sprint, ->(sprint_id) { where(sprint_id: sprint_id) }
end
