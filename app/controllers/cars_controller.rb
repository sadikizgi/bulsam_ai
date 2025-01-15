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
    feature_params = params.require(:features).permit(
      colors: [],
      kilometer: [:min, :max],
      price: [:min, :max],
      seller_types: [],
      transmission_types: []
    )

    @tracking.feature&.destroy

    @feature = @tracking.build_feature(
      colors: feature_params[:colors],
      kilometer_min: feature_params.dig(:kilometer, :min),
      kilometer_max: feature_params.dig(:kilometer, :max),
      price_min: feature_params.dig(:price, :min),
      price_max: feature_params.dig(:price, :max),
      seller_types: feature_params[:seller_types],
      transmission_types: feature_params[:transmission_types]
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
end
