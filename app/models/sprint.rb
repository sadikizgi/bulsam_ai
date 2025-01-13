class Sprint < ApplicationRecord
  has_many :car_scrapes, dependent: :destroy
  has_many :property_scrapes, dependent: :destroy
  has_many :scrap_issues, dependent: :destroy
  
  belongs_to :company
end
