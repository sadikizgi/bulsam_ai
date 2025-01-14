module Api
  class SerialsController < ApplicationController
    def index
      model = Model.find(params[:model_id])
      serials = model.serials
      render json: serials
    end
  end
end 