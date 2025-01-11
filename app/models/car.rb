class Car < ApplicationRecord
  belongs_to :vehicle
  has_many :car_scrapes
  
  validates :car_model, presence: true
  validates :car_serial, presence: true
  validates :car_motor_serial, presence: true
  validates :car_serial_name, presence: true
  validates :car_url, presence: true, uniqueness: true
end
