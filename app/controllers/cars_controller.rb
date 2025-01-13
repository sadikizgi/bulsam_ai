class CarsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  before_action :set_car, only: [:show]

  def index
    # Tüm araç scrapelerini getir, en son eklenenler önce
    @car_scrapes = CarScrape.joins(:sprint)
                           .order(created_at: :desc)
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
