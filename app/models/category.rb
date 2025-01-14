class Category < ApplicationRecord
  has_many :brands, dependent: :destroy
  has_many :models, through: :brands
  has_many :serials, through: :models

  validates :name, presence: true, uniqueness: true

  # Örnek kategoriler için scope'lar
  scope :otomobil, -> { find_by(name: 'otomobil') }
  scope :suv, -> { find_by(name: 'suv') }
  scope :ticari, -> { find_by(name: 'ticari') }

  def self.seed_default_categories
    %w[otomobil suv ticari].each do |name|
      find_or_create_by!(name: name)
    end
  end
end
