class CarsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  before_action :set_car, only: [:show, :start_tracking, :stop_tracking]

  def index
    @cars = current_user.cars.order(created_at: :desc)
  rescue
    @cars = []
  end

  def show
  end

  def new
    @car = Car.new
  end

  def create
    @car = current_user.cars.build(car_params)
    
    if @car.save
      redirect_to cars_path, notice: 'Araç takibi başlatıldı.'
    else
      render :new
    end
  end

  def start_tracking
    if @car.update(status: 'tracking')
      redirect_to cars_path, notice: 'Araç takibi başlatıldı.'
    else
      redirect_to cars_path, alert: 'Bir hata oluştu.'
    end
  end

  def stop_tracking
    if @car.update(status: 'stopped')
      redirect_to cars_path, notice: 'Araç takibi durduruldu.'
    else
      redirect_to cars_path, alert: 'Bir hata oluştu.'
    end
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end

  def car_params
    params.require(:car).permit(:brand, :model, :year, :price, :mileage, 
                              :fuel_type, :transmission, :location, :status)
  end
end
