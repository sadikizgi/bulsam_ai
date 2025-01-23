class CarsController < ApplicationController
  include ActionView::Helpers::DateHelper

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

  def sort_scrapes
    @car_tracking = CarTracking.find(params[:id])
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
  
    @scrapes = case params[:sort]
               when 'newest'
                 @car_tracking.filtered_scrapes.order(public_date: :desc)
               when 'oldest'
                 @car_tracking.filtered_scrapes.order(public_date: :asc)
               when 'price_asc'
                 @car_tracking.filtered_scrapes.order(price: :asc)
               when 'price_desc'
                 @car_tracking.filtered_scrapes.order(price: :desc)
               when 'km_asc'
                 @car_tracking.filtered_scrapes.order(km: :asc)
               when 'km_desc'
                 @car_tracking.filtered_scrapes.order(km: :desc)
               when 'year_desc'
                 @car_tracking.filtered_scrapes.order(year: :desc)
               when 'year_asc'
                 @car_tracking.filtered_scrapes.order(year: :asc)
               else
                 @car_tracking.filtered_scrapes.order(created_at: :desc)
               end
  
    @scrapes = @scrapes.distinct # Benzersiz kayıtları al
    @paginated_scrapes = @scrapes.page(page).per(5) # Sayfalama uygula
  
    total_pages = (@scrapes.count.to_f / 5).ceil
  
    current_time = Time.current
    render json: {
      scrapes: @paginated_scrapes.map { |scrape|
        hours_since_add = ((current_time - scrape.add_date) / 1.hour).round(2)
        is_within_24_hours = hours_since_add <= 24
        {
          id: scrape.id,
          title: scrape.title,
          price: scrape.price,
          km: scrape.km,
          year: scrape.year,
          color: scrape.color,
          city: scrape.city,
          image_url: scrape.image_url,
          product_url: scrape.product_url,
          public_date: I18n.l(scrape.public_date, format: :long),
          created_at_ago: time_ago_in_words(scrape.created_at),
          is_new: is_within_24_hours && scrape.is_new,
          add_date: scrape.add_date
        }
      },
      pagination: {
        total_items: @scrapes.count,
        current_page: page,
        total_pages: total_pages,
        has_previous: page > 1,
        has_next: page < total_pages
      }
    }
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
