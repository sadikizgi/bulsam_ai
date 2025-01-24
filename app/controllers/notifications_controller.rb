require 'ostruct'

class NotificationsController < ApplicationController
  def index
    @time_filter = params[:time_filter] || '24h'
    @per_page = 5

    # Get all notifications within selected time frame
    base_query = CarScrape.joins(:sprint)
                         .joins('INNER JOIN car_trackings ON car_trackings.id = sprints.car_tracking_id')
                         .joins('INNER JOIN categories ON car_trackings.category_id = categories.id')
                         .joins('LEFT JOIN categories parent_categories ON categories.parent_id = parent_categories.id')
                         .joins('LEFT JOIN car_tracking_features ON car_tracking_features.car_tracking_id = car_trackings.id')
                         .where(is_new: true)
                         .where('DATE(car_scrapes.public_date) >= ?', time_filter_to_duration.to_date)
                         .order(public_date: :desc)
                         .includes(sprint: { car_tracking: [:category, :brand, { category: :parent }] })

    # Apply tracking filters
    @all_notifications = base_query.where(<<-SQL)
      (
        car_tracking_features.id IS NULL
        OR
        (
          (car_tracking_features.year_min IS NULL OR car_scrapes.year >= car_tracking_features.year_min)
          AND
          (car_tracking_features.year_max IS NULL OR car_scrapes.year <= car_tracking_features.year_max)
          AND
          (car_tracking_features.kilometer_min IS NULL OR car_scrapes.km >= car_tracking_features.kilometer_min)
          AND
          (car_tracking_features.kilometer_max IS NULL OR car_scrapes.km <= car_tracking_features.kilometer_max)
          AND
          (car_tracking_features.price_min IS NULL OR car_scrapes.price >= car_tracking_features.price_min)
          AND
          (car_tracking_features.price_max IS NULL OR car_scrapes.price <= car_tracking_features.price_max)
          AND
          (
            car_tracking_features.colors IS NULL
            OR car_tracking_features.colors = '--- []\n'
            OR car_tracking_features.colors LIKE '%Tüm Renkler%'
            OR LOWER(car_scrapes.color) IN (
              SELECT LOWER(REGEXP_REPLACE(UNNEST(string_to_array(REGEXP_REPLACE(car_tracking_features.colors, '[\[\]"]', '', 'g'), ',')),' ', ''))
            )
          )
        )
      )
    SQL
    .distinct

    # Group all notifications by parent category
    @notifications_by_parent_category = {}
    @paginated_notifications = {}

    # Group all notifications by parent category first
    grouped_notifications = @all_notifications.group_by do |car| 
      category = car.sprint.car_tracking.category
      if category.parent.nil? && !Category.exists?(parent_id: category.id)
        # If category has no parent and is not a parent itself, use itself as parent
        category
      else
        category.parent || category
      end
    end

    grouped_notifications.each do |parent_category, cars|
      # First group by brand within this category
      cars_by_brand = cars.group_by { |car| car.sprint.car_tracking.brand&.name || car.title.split.first }
      
      # Initialize pagination for each brand
      @paginated_notifications[parent_category] = {}
      
      cars_by_brand.each do |brand_name, brand_cars|
        current_page = (params["page_#{parent_category.id}_#{brand_name.parameterize}"] || 1).to_i
        start_idx = (current_page - 1) * @per_page
        total_pages = (brand_cars.size.to_f / @per_page).ceil
        
        @paginated_notifications[parent_category][brand_name] = {
          cars: brand_cars[start_idx, @per_page] || [],
          current_page: current_page,
          total_pages: total_pages,
          total_count: brand_cars.size
        }
      end
      
      # Store all notifications for counts
      @notifications_by_parent_category[parent_category] = cars_by_brand
    end

    # Group notifications by source and tracking info for detailed counts
    @all_notifications_by_source = @all_notifications.group_by do |car|
      category = car.sprint.car_tracking.category
      parent_category = if category.parent.nil? && !Category.exists?(parent_id: category.id)
        category
      else
        category.parent || category
      end
      [parent_category, extract_source_from_url(car.product_url)]
    end

    @all_notifications_by_tracking = @all_notifications.group_by do |car|
      category = car.sprint.car_tracking.category
      parent_category = if category.parent.nil? && !Category.exists?(parent_id: category.id)
        category
      else
        category.parent || category
      end
      [parent_category, category, extract_source_from_url(car.product_url)]
    end
  end

  private

  def extract_source_from_url(url)
    case url
    when /arabam\.com/
      'Arabam.com'
    when /sahibinden\.com/
      'Sahibinden.com'
    else
      'Diğer'
    end
  end

  def time_filter_to_duration
    case @time_filter
    when '24h' then 24.hours.ago
    when '7d'  then 7.days.ago
    when 'all' then 30.days.ago
    else 24.hours.ago
    end
  end
end
