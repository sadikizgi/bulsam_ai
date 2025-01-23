class NotificationMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notification_mailer.new_car_notification.subject
  #
  def new_car_notification(user, car_scrapes)
    @user = user
    @car_scrapes = car_scrapes
    @tracking = car_scrapes.first.sprint.car_tracking
    
    tracking_info = if @tracking&.brand_name.present? && @tracking&.model_name.present?
      "#{@tracking.brand_name} #{@tracking.model_name}"
    else
      "Araç"
    end
    
    mail(
      to: @user.email,
      subject: "Yeni #{tracking_info} Bildirimi"
    )
  end
end
