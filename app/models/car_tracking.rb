require 'kaminari'

class CarTracking < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :brand
  belongs_to :model
  belongs_to :serial

  validates :websites, presence: true
  validates :cities, presence: true
  
  serialize :websites, coder: YAML
  serialize :cities, coder: YAML
  
  paginates_per 10
  
  def websites
    super || []
  end
  
  def cities
    super || []
  end
end 