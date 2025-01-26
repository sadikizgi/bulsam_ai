class PropertyType < ApplicationRecord
  has_many :property_trackings
  
  validates :name, presence: true, uniqueness: true
end 