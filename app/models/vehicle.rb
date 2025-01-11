class Vehicle < ApplicationRecord
  belongs_to :company
  has_many :cars
  
  validates :name, presence: true
end
