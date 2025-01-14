module Api
  class BrandsController < ApplicationController
    def index
      category = Category.find(params[:category_id])
      brands = category.brands
      render json: brands
    end
  end
end 