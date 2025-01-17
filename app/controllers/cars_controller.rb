class CarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tracking, only: [:destroy, :features, :update_features]

  def index
    @car_trackings = current_user.car_trackings
                                .includes(:category, :brand, :model, :serial, :feature)
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(10)
  end

  def create
    @tracking = current_user.car_trackings.build(tracking_params)
    
    Rails.logger.info "Tracking params: #{tracking_params.inspect}"
    Rails.logger.info "Tracking object: #{@tracking.inspect}"
    
    if @tracking.save
      render json: @tracking, status: :created
    else
      Rails.logger.error "Validation errors: #{@tracking.errors.full_messages}"
      render json: { errors: @tracking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @tracking.destroy
    redirect_to cars_path, notice: 'Araç takibi silindi.'
  end

  def features
    render json: @tracking.feature_attributes
  end

  def update_features
    @tracking.feature&.destroy

    @feature = @tracking.build_feature(
      colors: params[:colors],
      year_min: params[:year_min],
      year_max: params[:year_max],
      kilometer_min: params[:kilometer_min],
      kilometer_max: params[:kilometer_max],
      price_min: params[:price_min],
      price_max: params[:price_max],
      notification_frequency: params[:notification_frequency]
    )

    if @feature.save
      render json: @feature, status: :ok
    else
      render json: { errors: @feature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tracking
    @tracking = current_user.car_trackings.find(params[:id])
  end

  def tracking_params
    params.require(:tracking).permit(:category_id, :brand_id, :model_id, :serial_id, 
                                   websites: [], cities: [])
  end

  def feature_params
    params.permit(
      :year_min, :year_max,
      :kilometer_min, :kilometer_max,
      :price_min, :price_max,
      :notification_frequency,
      colors: []
    )
  end
end
