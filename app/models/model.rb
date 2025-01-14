class Model < ApplicationRecord
  belongs_to :brand
  has_many :serials, dependent: :destroy

  validates :name, presence: true
  validates :brand_id, presence: true

  delegate :category, to: :brand
  delegate :name, to: :category, prefix: true

  def full_name
    "#{brand.name} #{name}"
  end

  def full_name_with_category
    "#{full_name} (#{category_name})"
  end
end
