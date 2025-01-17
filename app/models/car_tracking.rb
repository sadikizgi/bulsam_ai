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
  has_one :car_tracking_feature, dependent: :destroy

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
      'notification_frequency'
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
    scope = car_scrapes.order('car_scrapes.created_at DESC')
    
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

  def last_scrape_time
    car_scrapes.maximum('car_scrapes.created_at')
  end

  def scrape_count_since_last_check
    return 0 unless feature&.notification_frequency.present?
    
    frequency = case feature.notification_frequency
      when '30m' then 30.minutes
      when '1h' then 1.hour
      when '5h' then 5.hours
      when '12h' then 12.hours
      when '1d' then 1.day
      when '3d' then 3.days
      when '1w' then 1.week
    end

    car_scrapes.where('car_scrapes.created_at > ?', frequency.ago).count
  end

  def total_scrape_count
    car_scrapes.count
  end

  def last_job_run
    sprint = car_scrapes.joins(:sprint)
                       .select('sprints.*')
                       .order('sprints.completed_at DESC NULLS LAST, sprints.created_at DESC')
                       .first

    return nil unless sprint

    # Eğer sprint tamamlanmışsa completed_at'i, değilse created_at'i döndür
    sprint.completed_at || sprint.created_at
  end

  def daily_job_runs
    # Son 24 saat içinde tamamlanan sprint'leri say
    car_scrapes.joins(:sprint)
               .where('sprints.completed_at > ? OR (sprints.completed_at IS NULL AND sprints.created_at > ?)', 
                     24.hours.ago, 24.hours.ago)
               .select('DISTINCT sprints.id')
               .count
  end

  def total_job_runs
    # Bu category için toplam sprint sayısı
    car_scrapes.joins(:sprint)
               .select('DISTINCT sprints.id')
               .count
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