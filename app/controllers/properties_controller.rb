class PropertiesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :start_tracking, :stop_tracking]

  def index
    @properties = current_user.properties.order(created_at: :desc)
  rescue
    @properties = []
  end

  def show
  end

  def new
    @property = Property.new
  end

  def create
    @property = current_user.properties.build(property_params)
    
    if @property.save
      redirect_to properties_path, notice: 'Emlak takibi başlatıldı.'
    else
      render :new
    end
  end

  def start_tracking
    if @property.update(status: 'tracking')
      redirect_to properties_path, notice: 'Emlak takibi başlatıldı.'
    else
      redirect_to properties_path, alert: 'Bir hata oluştu.'
    end
  end

  def stop_tracking
    if @property.update(status: 'stopped')
      redirect_to properties_path, notice: 'Emlak takibi durduruldu.'
    else
      redirect_to properties_path, alert: 'Bir hata oluştu.'
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def property_params
    params.require(:property).permit(:property_type, :rooms, :size, :floor, 
                                   :age, :price, :location, :features, :status)
  end
end
