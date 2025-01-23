class SendNewCarNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    # Her bir takip için yeni araçları kontrol et
    CarTracking.find_each do |tracking|
      # Sprint üzerinden araçları bul
      new_cars = CarScrape.joins(:sprint)
                         .where(sprints: { car_tracking_id: tracking.id })
                         .where(is_new: true, mail_sent: false)
                         .to_a
      
      if new_cars.any?
        begin
          # Kullanıcıya mail gönder
          NotificationMailer.new_car_notification(tracking.user, new_cars).deliver_later
          
          # Mail gönderildi olarak işaretle
          CarScrape.where(id: new_cars.map(&:id)).update_all(mail_sent: true, mail_sent_at: Time.current)
        rescue => e
          Rails.logger.error "Mail gönderimi sırasında hata: #{e.message}"
        end
      end
    end
  end
end
