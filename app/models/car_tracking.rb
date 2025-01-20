require 'kaminari'

class CarTracking < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :brand, optional: true
  belongs_to :model, optional: true
  belongs_to :serial, optional: true
  has_one :car_tracking_feature, dependent: :destroy
  has_many :sprints
  has_many :car_scrapes, through: :sprints

  serialize :websites, coder: YAML
  serialize :cities, coder: YAML
  
  delegate :colors, :year_min, :year_max, :kilometer_min, :kilometer_max, :price_min, :price_max, :notification_frequency,
           to: :car_tracking_feature, prefix: false, allow_nil: true
  
  before_save :ensure_array_format

  after_initialize :set_default_values, if: :new_record?

  def filtered_scrapes
    base_query = car_scrapes.includes(:sprint)
    
    if car_tracking_feature.present?
      if car_tracking_feature.colors.present?
        unless car_tracking_feature.colors.include?('Tüm Renkler')
          base_query = base_query.where('LOWER(color) IN (?)', car_tracking_feature.colors.map(&:downcase))
        end
      end
      
      if car_tracking_feature.year_min.present?
        base_query = base_query.where('year >= ?', car_tracking_feature.year_min)
      end
      
      if car_tracking_feature.year_max.present?
        base_query = base_query.where('year <= ?', car_tracking_feature.year_max)
      end
      
      if car_tracking_feature.kilometer_min.present?
        base_query = base_query.where('km >= ?', car_tracking_feature.kilometer_min)
      end
      
      if car_tracking_feature.kilometer_max.present?
        base_query = base_query.where('km <= ?', car_tracking_feature.kilometer_max)
      end
      
      if car_tracking_feature.price_min.present?
        base_query = base_query.where('price >= ?', car_tracking_feature.price_min)
      end
      
      if car_tracking_feature.price_max.present?
        base_query = base_query.where('price <= ?', car_tracking_feature.price_max)
      end
    end
    
    base_query.order(created_at: :desc)
  end

  def recent_scrapes(page = 1)
    filtered_scrapes.page(page).per(5)
  end

  private

  def ensure_array_format
    self.websites = [] if websites.nil?
    self.cities = [] if cities.nil?
  end

  def set_default_values
    self.daily_scrape_count ||= 0
    self.total_scrape_count ||= 0
  end
end 