class Serial < ApplicationRecord
  belongs_to :model

  validates :name, presence: true
  validates :model_id, presence: true
  validates :engine_size, presence: true

  delegate :brand, to: :model
  delegate :category, to: :brand, prefix: true

  def full_name
    "#{model.brand.name} #{model.name} #{name}"
  end

  def full_name_with_engine
    "#{full_name} #{engine_size}"
  end
end
