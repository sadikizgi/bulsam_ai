# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/new_car_notification
  def new_car_notification
    NotificationMailer.new_car_notification
  end
end
