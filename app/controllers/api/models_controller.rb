module Api
  class ModelsController < ApplicationController
    def index
      brand = Brand.find(params[:brand_id])
      models = brand.models
      render json: models
    end
  end
end 