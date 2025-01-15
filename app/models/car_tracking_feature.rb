class CarTrackingFeature < ApplicationRecord
  belongs_to :car_tracking

  validates :kilometer_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :kilometer_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  
  validate :kilometer_range_valid
  validate :price_range_valid
  
  private
  
  def kilometer_range_valid
    if kilometer_min.present? && kilometer_max.present? && kilometer_min > kilometer_max
      errors.add(:kilometer_min, "minimum kilometre maksimum kilometreden büyük olamaz")
    end
  end
  
  def price_range_valid
    if price_min.present? && price_max.present? && price_min > price_max
      errors.add(:price_min, "minimum fiyat maksimum fiyattan büyük olamaz")
    end
  end
end
