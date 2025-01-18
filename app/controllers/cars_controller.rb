class CarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tracking, only: [:destroy, :features, :update_features]

  def index
    @car_trackings = if user_signed_in?
      current_user.car_trackings
                  .includes(:category, :brand, :model, :serial, :car_tracking_feature)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(10)
    else
      CarTracking.none
    end
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
    if @tracking.car_tracking_feature.present?
      render json: {
        colors: @tracking.car_tracking_feature.colors,
        year_min: @tracking.car_tracking_feature.year_min,
        year_max: @tracking.car_tracking_feature.year_max,
        kilometer_min: @tracking.car_tracking_feature.kilometer_min,
        kilometer_max: @tracking.car_tracking_feature.kilometer_max,
        price_min: @tracking.car_tracking_feature.price_min,
        price_max: @tracking.car_tracking_feature.price_max,
        notification_frequency: @tracking.car_tracking_feature.notification_frequency
      }
    else
      render json: {}
    end
  end

  def update_features
    @tracking.car_tracking_feature&.destroy

    @feature = @tracking.build_car_tracking_feature(feature_params)

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
