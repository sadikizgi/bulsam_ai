class DashboardController < ApplicationController
  before_action :authenticate_user! # Kullanıcı giriş kontrolü

  def index
    # Dashboard ile ilgili veriler burada hazırlanabilir
  end
end