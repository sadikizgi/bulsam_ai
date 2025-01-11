class Company < ApplicationRecord
  belongs_to :category
  has_many :sprints
  
  validates :name, presence: true, uniqueness: true
end
