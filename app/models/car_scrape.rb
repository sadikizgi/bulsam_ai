class CarScrape < ApplicationRecord
  belongs_to :sprint
  belongs_to :car_tracking, optional: true
  
  has_many :images, class_name: 'ScrapImage', as: :scrape, dependent: :destroy
  
  validates :title, presence: true
  validates :product_url, presence: true, uniqueness: { scope: :sprint_id }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  before_save :set_add_date
  before_save :check_new_status
  
  private
  
  def set_add_date
    self.add_date ||= Time.current
  end

  def check_new_status
    # Eğer public_date'den itibaren 24 saatten fazla zaman geçmişse is_new'i false yap
    if public_date.present? && public_date < 24.hours.ago
      self.is_new = false
      self.is_replay = false
    end
  end
end
