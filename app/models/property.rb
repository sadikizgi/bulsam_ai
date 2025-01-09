class Property < ApplicationRecord
  belongs_to :user

  validates :property_type, presence: true
  validates :rooms, presence: true
  validates :size, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :floor, presence: true
  validates :age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :location, presence: true
  validates :status, presence: true

  # Emlak durumu için enum
  enum status: {
    tracking: 'tracking',
    stopped: 'stopped'
  }

  # Emlak tipi için enum
  enum property_type: {
    apartment: 'Daire',
    villa: 'Villa',
    detached_house: 'Müstakil Ev',
    office: 'Ofis',
    shop: 'Dükkan',
    land: 'Arsa'
  }

  # Oda sayısı için enum
  enum rooms: {
    studio: 'Stüdyo',
    one_plus_one: '1+1',
    two_plus_one: '2+1',
    three_plus_one: '3+1',
    four_plus_one: '4+1',
    four_plus_two: '4+2',
    five_plus_one: '5+1',
    five_plus_two: '5+2'
  }

  # Features alanı için serialize
  serialize :features, Array
end
