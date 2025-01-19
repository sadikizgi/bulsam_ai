class NotificationsController < ApplicationController
  def index
    @page = (params[:page] || 1).to_i
    @per_page = 5

    @all_notifications = CarScrape.joins(:sprint)
                            .joins('INNER JOIN companies ON sprints.company_id = companies.id')
                            .joins('INNER JOIN categories ON categories.company_id = companies.id')
                            .joins('INNER JOIN car_trackings ON car_trackings.category_id = categories.id')
                            .joins('LEFT JOIN categories parent_categories ON categories.parent_id = parent_categories.id')
                            .where(is_new: true)
                            .where('car_scrapes.created_at > ?', 24.hours.ago)
                            .order(created_at: :desc)
                            .includes(:sprint)
                            .distinct

    @total_count = @all_notifications.count
    @total_pages = (@total_count.to_f / @per_page).ceil

    @paginated_notifications = @all_notifications
                                .limit(@per_page)
                                .offset((@page - 1) * @per_page)

    # Ana kategori bazında tüm araçlar
    @all_notifications_by_parent_category = @all_notifications
                                            .group_by { |car| car.sprint.car_tracking.category.parent || car.sprint.car_tracking.category }

    # Sayfalanmış görünüm için
    @notifications_by_parent_category = @paginated_notifications
                                        .group_by { |car| car.sprint.car_tracking.category.parent || car.sprint.car_tracking.category }

    # Kaynak bazında tüm araçlar
    @all_notifications_by_source = @all_notifications
                                   .group_by { |car| [car.sprint.car_tracking.category.parent || car.sprint.car_tracking.category,
                                                    extract_source_from_url(car.product_url)] }

    # Takip bazında tüm araçlar
    @all_notifications_by_tracking = @all_notifications
                                     .group_by { |car| [car.sprint.car_tracking.category.parent || car.sprint.car_tracking.category,
                                                      car.sprint.car_tracking.category,
                                                      extract_source_from_url(car.product_url)] }
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
