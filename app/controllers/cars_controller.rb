class CarsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Paginatable
  
  before_action :authenticate_user!
  before_action :set_car, only: [:show]

  def index
    @car_scrapes = paginate(
      CarScrape.joins(:sprint)
               .order(created_at: :desc)
    )
    
    @total_count = CarScrape.count
    @total_pages = (@total_count.to_f / per_page).ceil
  rescue
    @car_scrapes = []
    @total_count = 0
    @total_pages = 0
  end

  def show
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end
end
