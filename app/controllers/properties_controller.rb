class PropertiesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Paginatable
  
  before_action :authenticate_user!
  before_action :set_property, only: [:show]

  def index
    @property_scrapes = paginate(
      PropertyScrape.joins(:sprint)
                    .order(created_at: :desc)
    )
    
    @total_count = PropertyScrape.count
    @total_pages = (@total_count.to_f / per_page).ceil
  rescue
    @property_scrapes = []
    @total_count = 0
    @total_pages = 0
  end

  def show
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end
end
