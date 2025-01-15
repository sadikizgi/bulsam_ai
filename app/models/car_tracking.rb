require 'kaminari'

class CarTracking < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :brand, optional: true
  belongs_to :model, optional: true
  belongs_to :serial, optional: true
  has_one :feature, class_name: 'CarTrackingFeature', dependent: :destroy

  validates :websites, presence: true
  validates :cities, presence: true
  validates :category_id, presence: true
  
  serialize :websites, coder: YAML
  serialize :cities, coder: YAML
  
  paginates_per 10
  
  def websites
    super || []
  end
  
  def cities
    super || []
  end

  def feature_attributes
    feature&.attributes&.slice(
      'colors',
      'kilometer_min',
      'kilometer_max',
      'price_min',
      'price_max',
      'seller_types',
      'transmission_types'
    ) || {}
  end
end 