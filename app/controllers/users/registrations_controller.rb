# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: [:new, :create, :cancel]
  
  def create
    super do |resource|
      if resource.persisted?
        flash[:notice] = "Kayıt başarıyla oluşturuldu! Lütfen giriş yapın."
        sign_out resource
        return redirect_to new_user_session_path
      end
    end
  end
end
