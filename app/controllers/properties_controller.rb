class PropertiesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!
  before_action :set_property, only: [:show]

  def index
    # Kullanıcının takip ettiği emlakları PropertyScrape üzerinden getir
    @property_scrapes = PropertyScrape.joins(:sprint)
                                    .select('DISTINCT ON (property_scrapes.property_id) property_scrapes.*')
                                    .order('property_scrapes.property_id, property_scrapes.created_at DESC')
  rescue
    @property_scrapes = []
  end

  def show
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end
end
