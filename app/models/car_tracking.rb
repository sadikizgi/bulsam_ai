require 'kaminari'

class CarTracking < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :brand, optional: true
  belongs_to :model, optional: true
  belongs_to :serial, optional: true
  has_one :feature, class_name: 'CarTrackingFeature', dependent: :destroy
  has_many :sprints, through: :category
  has_many :car_scrapes, through: :sprints

  validates :websites, presence: true
  validates :cities, presence: true
  validates :category_id, presence: true
  
  serialize :websites, coder: YAML
  serialize :cities, coder: YAML
  
  paginates_per 10
  
  after_create :schedule_scraping_job
  
  def websites
    super || []
  end
  
  def cities
    super || []
  end

  def feature_attributes
    feature&.attributes&.slice(
      'colors',
      'kilometer_min',
      'kilometer_max',
      'price_min',
      'price_max',
      'seller_types',
      'transmission_types'
    ) || {}
  end

  def recent_scrapes(page = 1)
    car_scrapes.order(created_at: :desc).page(page).per(5)
  end

  private

  def schedule_scraping_job
    return unless websites.include?('arabam')

    url = if serial&.serial_url.present?
            serial.serial_url
          elsif model&.model_url.present?
            model.model_url
          elsif brand&.brand_url.present?
            brand.brand_url
          else
            category.category_url
          end

    ScrapeArabamMainJob.perform_later([url])
  end
end 