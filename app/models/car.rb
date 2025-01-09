class Car < ApplicationRecord
  belongs_to :user

  validates :brand, presence: true
  validates :model, presence: true
  validates :year, presence: true, numericality: { only_integer: true }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :mileage, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fuel_type, presence: true
  validates :transmission, presence: true
  validates :location, presence: true
  validates :status, presence: true

  # Araç durumu için enum
  enum status: {
    tracking: 'tracking',
    stopped: 'stopped'
  }

  # Yakıt tipi için enum
  enum fuel_type: {
    gasoline: 'Benzin',
    diesel: 'Dizel',
    lpg: 'LPG',
    hybrid: 'Hibrit',
    electric: 'Elektrik'
  }

  # Vites tipi için enum
  enum transmission: {
    manual: 'Manuel',
    automatic: 'Otomatik',
    semi_automatic: 'Yarı Otomatik'
  }
end
