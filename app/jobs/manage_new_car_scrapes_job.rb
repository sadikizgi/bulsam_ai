class ManageNewCarScrapesJob < ApplicationJob
  queue_as :default

  def perform
    # 24 saatten eski yeni araçların etiketini kaldır
    # CarScrape.where(is_new: true)
    #          .where('created_at < ?', 24.hours.ago)
    #          .update_all(is_new: false)

    # Bildirim gönderilmemiş yeni araçları işaretle
    # CarScrape.where(is_new: true)
    #          .where(notification_sent: false)
    #          .find_each do |scrape|
    #   # Burada bildirim gönderme işlemi yapılabilir
    #   # Örneğin: NotificationService.send_new_car_notification(scrape)
      
    #   scrape.update(
    #     notification_sent: true,
    #     notification_sent_at: Time.current
    #   )
    # end
  end
end 