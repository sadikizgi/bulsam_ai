class ScrapeCategoryJob < ApplicationJob
  queue_as :default

  def perform(frequency)
    # Belirtilen frekansa göre kategorileri bul
    trackings = CarTracking.joins(:car_tracking_feature)
                          .where(car_tracking_features: { notification_frequency: frequency})
                          .distinct

    # Her tracking için scraping işlemini başlat
    trackings.each do |tracking|
      urls = []
      
      # Tracking'in URL'lerini topla
      if tracking.serial&.serial_url.present?
        urls << tracking.serial.serial_url
      elsif tracking.model&.model_url.present?
        urls << tracking.model.model_url
      elsif tracking.brand&.brand_url.present?
        urls << tracking.brand.brand_url
      else
        urls << tracking.category.category_url
      end

      # Sprint oluştur ve tracking ile ilişkilendir
      sprint = Sprint.find_or_create_by!(
        company_id: tracking.category.company_id,
        car_tracking_id: tracking.id
      )

      # Scraping job'unu başlat
      ScrapeArabamMainJob.perform_later(urls, sprint.id)

      # Tracking bilgilerini güncelle
      tracking.increment!(:total_scrape_count)
      tracking.increment!(:daily_scrape_count) if tracking.last_scrape_at&.today?
      tracking.update(last_scrape_at: Time.current)
    end
  end
end 