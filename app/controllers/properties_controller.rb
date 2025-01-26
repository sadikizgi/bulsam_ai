class PropertiesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Paginatable
  include ActionView::Helpers::DateHelper
  
  before_action :authenticate_user!
  before_action :set_property, only: [:show]
  before_action :set_tracking, only: [:destroy, :features, :update_features]

  def index
    @property_trackings = if user_signed_in?
      current_user.property_trackings
                  .includes(:category, :property_type, :property_tracking_feature)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(10)
    else
      PropertyTracking.none
    end
  end

  def create
    @tracking = current_user.property_trackings.build(tracking_params)
    
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
    redirect_to properties_path, notice: 'Emlak takibi silindi.'
  end

  def features
    if @tracking.property_tracking_feature.present?
      render json: {
        room_count: @tracking.property_tracking_feature.room_count,
        floor_min: @tracking.property_tracking_feature.floor_min,
        floor_max: @tracking.property_tracking_feature.floor_max,
        size_min: @tracking.property_tracking_feature.size_min,
        size_max: @tracking.property_tracking_feature.size_max,
        price_min: @tracking.property_tracking_feature.price_min,
        price_max: @tracking.property_tracking_feature.price_max,
        notification_frequency: @tracking.property_tracking_feature.notification_frequency
      }
    else
      render json: {}
    end
  end

  def update_features
    @tracking.property_tracking_feature&.destroy

    @feature = @tracking.build_property_tracking_feature(feature_params)

    if @feature.save
      render json: @feature, status: :ok
    else
      render json: { errors: @feature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def sort_scrapes
    @property_tracking = PropertyTracking.find(params[:id])
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
  
    @scrapes = case params[:sort]
               when 'newest'
                 @property_tracking.filtered_scrapes.order(public_date: :desc)
               when 'oldest'
                 @property_tracking.filtered_scrapes.order(public_date: :asc)
               when 'price_asc'
                 @property_tracking.filtered_scrapes.order(price: :asc)
               when 'price_desc'
                 @property_tracking.filtered_scrapes.order(price: :desc)
               when 'size_asc'
                 @property_tracking.filtered_scrapes.order(size: :asc)
               when 'size_desc'
                 @property_tracking.filtered_scrapes.order(size: :desc)
               else
                 @property_tracking.filtered_scrapes.order(created_at: :desc)
               end
  
    @scrapes = @scrapes.distinct
    @paginated_scrapes = @scrapes.page(page).per(5)
  
    total_pages = (@scrapes.count.to_f / 5).ceil
  
    render json: {
      scrapes: @paginated_scrapes.map { |scrape|
        {
          id: scrape.id,
          title: scrape.title,
          price: scrape.price,
          size: scrape.size,
          room_count: scrape.room_count,
          floor: scrape.floor,
          city: scrape.city,
          image_url: scrape.image_url,
          product_url: scrape.product_url,
          public_date: I18n.l(scrape.public_date, format: :long),
          created_at_ago: time_ago_in_words(scrape.created_at),
          is_new: scrape.is_new,
          is_replay: scrape.is_replay,
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

  def show
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def set_tracking
    @tracking = current_user.property_trackings.find(params[:id])
  end

  def tracking_params
    params.require(:tracking).permit(:category_id, :property_type_id, 
                                   websites: [], cities: [])
  end

  def feature_params
    params.permit(
      :floor_min, :floor_max,
      :size_min, :size_max,
      :price_min, :price_max,
      :notification_frequency,
      room_count: []
    )
  end
end
