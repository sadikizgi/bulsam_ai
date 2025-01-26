require 'kaminari'

class PropertyTracking < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :property_type, optional: true
  has_one :property_tracking_feature, dependent: :destroy
  has_many :sprints
  has_many :property_scrapes, through: :sprints

  serialize :websites, coder: YAML
  serialize :cities, coder: YAML
  
  delegate :room_count, :floor_min, :floor_max, :size_min, :size_max, :price_min, :price_max, :notification_frequency,
           to: :property_tracking_feature, prefix: false, allow_nil: true
  
  before_save :ensure_array_format

  after_initialize :set_default_values, if: :new_record?

  def filtered_scrapes
    base_query = property_scrapes.includes(:sprint)
    
    if property_tracking_feature.present?
      if property_tracking_feature.room_count.present?
        unless property_tracking_feature.room_count.include?('Tümü')
          base_query = base_query.where('room_count IN (?)', property_tracking_feature.room_count)
        end
      end
      
      if property_tracking_feature.floor_min.present?
        base_query = base_query.where('floor >= ?', property_tracking_feature.floor_min)
      end
      
      if property_tracking_feature.floor_max.present?
        base_query = base_query.where('floor <= ?', property_tracking_feature.floor_max)
      end
      
      if property_tracking_feature.size_min.present?
        base_query = base_query.where('size >= ?', property_tracking_feature.size_min)
      end
      
      if property_tracking_feature.size_max.present?
        base_query = base_query.where('size <= ?', property_tracking_feature.size_max)
      end
      
      if property_tracking_feature.price_min.present?
        base_query = base_query.where('price >= ?', property_tracking_feature.price_min)
      end
      
      if property_tracking_feature.price_max.present?
        base_query = base_query.where('price <= ?', property_tracking_feature.price_max)
      end
    end
    
    base_query
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