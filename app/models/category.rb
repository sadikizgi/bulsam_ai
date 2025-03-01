class Category < ApplicationRecord
  belongs_to :company
  has_many :brands, dependent: :destroy
  has_many :models, through: :brands
  has_many :serials, through: :models
  has_many :sprints, through: :company
  has_many :car_trackings

  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'

  validates :name, presence: true, uniqueness: true

  # Örnek kategoriler için scope'lar
  scope :otomobil, -> { find_by(name: 'otomobil') }
  scope :suv, -> { find_by(name: 'suv') }
  scope :ticari, -> { find_by(name: 'ticari') }
  scope :main_categories, -> { where(parent_id: nil) }
  scope :sub_categories, -> { where.not(parent_id: nil) }

  def self.seed_default_categories
    %w[otomobil suv ticari].each do |name|
      find_or_create_by!(name: name)
    end
  end
end
