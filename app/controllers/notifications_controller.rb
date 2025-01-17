class NotificationsController < ApplicationController
  def index
    @new_cars = CarScrape.joins(:sprint)
                         .joins('INNER JOIN companies ON sprints.company_id = companies.id')
                         .joins('INNER JOIN categories ON categories.company_id = companies.id')
                         .joins('INNER JOIN car_trackings ON car_trackings.category_id = categories.id')
                         .where(is_new: true)
                         .where('car_scrapes.created_at > ?', 24.hours.ago)
                         .order(created_at: :desc)
                         .includes(:sprint)
                         .distinct
  end
end
