class NotificationsController < ApplicationController
  def index
    @per_page = 5

    # Get all notifications within last 24 hours
    @all_notifications = CarScrape.joins(:sprint)
                          .joins('INNER JOIN companies ON sprints.company_id = companies.id')
                          .joins('INNER JOIN car_trackings ON car_trackings.id = sprints.car_tracking_id')
                          .joins('INNER JOIN categories ON car_trackings.category_id = categories.id')
                          .joins('LEFT JOIN categories parent_categories ON categories.parent_id = parent_categories.id')
                          .where(is_new: true)
                          .where('car_scrapes.created_at > ?', 24.hours.ago)
                          .order(created_at: :desc)
                          .includes(sprint: { car_tracking: { category: :parent } })
                          .distinct

    # Group all notifications by parent category
    @notifications_by_parent_category = {}
    @paginated_notifications_by_parent = {}
    @total_pages_by_parent = {}
    @current_page_by_parent = {}

    # Group all notifications by parent category first
    grouped_notifications = @all_notifications.group_by do |car| 
      category = car.sprint.car_tracking.category
      category.parent || category
    end

    grouped_notifications.each do |parent_category, cars|
      # Get current page for this category
      current_page = (params["page_#{parent_category.id}"] || 1).to_i
      @current_page_by_parent[parent_category.id] = current_page

      # Calculate total pages for this category
      total_pages = (cars.size.to_f / @per_page).ceil
      @total_pages_by_parent[parent_category.id] = total_pages

      # Store all notifications for counts
      @notifications_by_parent_category[parent_category] = cars

      # Get paginated notifications for this category
      start_idx = (current_page - 1) * @per_page
      @paginated_notifications_by_parent[parent_category] = cars[start_idx, @per_page] || []
    end

    # Group notifications by source and tracking info for detailed counts
    @all_notifications_by_source = @all_notifications.group_by do |car|
      category = car.sprint.car_tracking.category
      parent_category = category.parent || category
      [parent_category, extract_source_from_url(car.product_url)]
    end

    @all_notifications_by_tracking = @all_notifications.group_by do |car|
      category = car.sprint.car_tracking.category
      parent_category = category.parent || category
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
end
