class CarsController < ApplicationController
  before_action :authenticate_user!

  def index
    @car_trackings = current_user.car_trackings
                                .includes(:category, :brand, :model, :serial)
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(10)
  end

  def create
    @tracking = current_user.car_trackings.build(tracking_params)
    
    if @tracking.save
      render json: @tracking, status: :created
    else
      render json: { errors: @tracking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @tracking = current_user.car_trackings.find(params[:id])
    @tracking.destroy
    redirect_to cars_path, notice: 'Araç takibi silindi.'
  end

  private

  def tracking_params
    params.require(:tracking).permit(:category_id, :brand_id, :model_id, :serial_id, 
                                   websites: [], cities: [])
  end
end
