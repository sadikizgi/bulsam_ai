class CarScrape < ApplicationRecord
  belongs_to :sprint
  
  has_many :images, class_name: 'ScrapImage', as: :scrape, dependent: :destroy
  
  validates :title, presence: true
  validates :product_url, presence: true, uniqueness: { scope: :sprint_id }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  before_save :set_add_date
  
  private
  
  def set_add_date
    self.add_date ||= Time.current
  end
end
