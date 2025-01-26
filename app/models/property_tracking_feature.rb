class PropertyTrackingFeature < ApplicationRecord
  belongs_to :property_tracking

  serialize :room_count, coder: YAML

  validates :notification_frequency, presence: true, inclusion: { in: %w[instant daily weekly] }
  validates :price_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :size_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :size_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :floor_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :floor_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  
  validate :price_range_validation
  validate :size_range_validation
  validate :floor_range_validation

  private

  def price_range_validation
    if price_min.present? && price_max.present? && price_min > price_max
      errors.add(:price_min, "minimum fiyat maksimum fiyattan büyük olamaz")
    end
  end

  def size_range_validation
    if size_min.present? && size_max.present? && size_min > size_max
      errors.add(:size_min, "minimum metrekare maksimum metrekareden büyük olamaz")
    end
  end

  def floor_range_validation
    if floor_min.present? && floor_max.present? && floor_min > floor_max
      errors.add(:floor_min, "minimum kat maksimum kattan büyük olamaz")
    end
  end
end 