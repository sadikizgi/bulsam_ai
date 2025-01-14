class Brand < ApplicationRecord
  belongs_to :category
  has_many :models, dependent: :destroy
  has_many :serials, through: :models

  validates :name, presence: true
  validates :category_id, presence: true

  delegate :name, to: :category, prefix: true

  def full_name
    "#{name} (#{category_name})"
  end
end
