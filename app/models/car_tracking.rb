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
    attrs = feature&.attributes&.slice(
      'colors',
      'year_min',
      'year_max',
      'kilometer_min',
      'kilometer_max',
      'price_min',
      'price_max',
      'seller_types',
      'transmission_types'
    ) || {}

    if attrs['colors'].present?
      attrs['colors'] = feature.colors
    end

    attrs
  end

  def recent_scrapes(page = 1)
    filtered_scrapes.page(page).per(5)
  end

  def filtered_scrapes
    scope = car_scrapes.order(created_at: :desc)
    
    return scope unless feature.present?

    if feature.colors.present? && feature.colors.any?
      color_conditions = feature.colors.map { |color| "LOWER(color) LIKE ?" }
      color_values = feature.colors.map { |color| "%#{color.downcase}%" }
      scope = scope.where(color_conditions.join(' OR '), *color_values)
    end

    if feature.year_min.present?
      scope = scope.where('year >= ?', feature.year_min.to_i)
    end

    if feature.year_max.present?
      scope = scope.where('year <= ?', feature.year_max.to_i)
    end

    if feature.kilometer_min.present?
      scope = scope.where('km >= ?', feature.kilometer_min.to_i)
    end

    if feature.kilometer_max.present?
      scope = scope.where('km <= ?', feature.kilometer_max.to_i)
    end

    if feature.price_min.present?
      scope = scope.where('price >= ?', feature.price_min.to_i)
    end

    if feature.price_max.present?
      scope = scope.where('price <= ?', feature.price_max.to_i)
    end

    scope
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