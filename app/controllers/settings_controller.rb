class SettingsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Şimdilik boş bırakıyoruz, ileride kullanıcı ayarları eklenecek
  end
end
