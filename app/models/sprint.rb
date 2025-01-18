class Sprint < ApplicationRecord
  belongs_to :car_tracking
  belongs_to :company
  has_many :car_scrapes, dependent: :destroy
  has_many :property_scrapes, dependent: :destroy
  has_many :scrap_issues, dependent: :destroy
end
