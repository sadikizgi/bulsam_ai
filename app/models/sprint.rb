class Sprint < ApplicationRecord
  has_many :car_scrapes, dependent: :destroy
  has_many :property_scrapes, dependent: :destroy
  has_many :scrap_issues, dependent: :destroy
  
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  
  scope :active, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  scope :completed, -> { where('end_date < ?', Time.current) }
  scope :upcoming, -> { where('start_date > ?', Time.current) }
end
