class Company < ApplicationRecord
  has_many :categories
  has_many :sprints
  
  validates :name, presence: true, uniqueness: true
end
