class CarTrackingFeature < ApplicationRecord
  belongs_to :car_tracking

  validates :kilometer_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :kilometer_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :year_min, numericality: { greater_than_or_equal_to: 1900, less_than_or_equal_to: Time.current.year, allow_nil: true }
  validates :year_max, numericality: { greater_than_or_equal_to: 1900, less_than_or_equal_to: Time.current.year, allow_nil: true }
  
  before_save :convert_values_to_integer
  
  validate :kilometer_range_valid
  validate :price_range_valid
  validate :year_range_valid
  
  def colors
    return [] if self[:colors].blank?
    self[:colors].split(',').map(&:strip)
  end

  def colors=(value)
    value = Array(value).reject(&:blank?).map(&:strip)
    self[:colors] = value.join(',')
  end
  
  private
  
  def convert_values_to_integer
    self.kilometer_min = kilometer_min.to_i if kilometer_min.present?
    self.kilometer_max = kilometer_max.to_i if kilometer_max.present?
    self.price_min = price_min.to_i if price_min.present?
    self.price_max = price_max.to_i if price_max.present?
    self.year_min = year_min.to_i if year_min.present?
    self.year_max = year_max.to_i if year_max.present?
  end
  
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

  def year_range_valid
    if year_min.present? && year_max.present? && year_min > year_max
      errors.add(:year_min, "minimum yıl maksimum yıldan büyük olamaz")
    end
  end
end
