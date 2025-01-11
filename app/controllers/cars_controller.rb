class CarsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  before_action :set_car, only: [:show]

  def index
    # Kullanıcının takip ettiği araçları CarScrape üzerinden getir
    @car_scrapes = CarScrape.joins(:sprint)
                           .select('DISTINCT ON (car_scrapes.car_id) car_scrapes.*')
                           .order('car_scrapes.car_id, car_scrapes.created_at DESC')
  rescue
    @car_scrapes = []
  end

  def show
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end
end
