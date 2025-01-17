class UpdateCarScrapesJob < ApplicationJob
  queue_as :default

  def perform
    # Her bir takip için kontrol et
    CarTracking.find_each do |tracking|
      # Son 1 saat içinde eklenen ve filtrelere uyan araçları bul
      new_scrapes = tracking.car_scrapes
                           .where('created_at > ?', 1.hour.ago)
                           .where(is_new: false)

      # Filtrelere uyan araçları işaretle
      new_scrapes.each do |scrape|
        if matches_filters?(tracking, scrape)
          scrape.update(is_new: true)
        end
      end
    end
  end

  private

  def matches_filters?(tracking, scrape)
    feature = tracking.car_tracking_feature
    return true unless feature # Eğer özellik yoksa hepsi uysun

    matches = true

    # Renk kontrolü
    if feature.colors.present?
      matches = false unless feature.colors.include?(scrape.color)
    end

    # Yıl kontrolü
    if feature.year_min.present? && feature.year_max.present?
      matches = false unless (feature.year_min..feature.year_max).include?(scrape.year)
    end

    # Kilometre kontrolü
    if feature.kilometer_min.present? && feature.kilometer_max.present?
      matches = false unless (feature.kilometer_min..feature.kilometer_max).include?(scrape.km)
    end

    # Fiyat kontrolü
    if feature.price_min.present? && feature.price_max.present?
      matches = false unless (feature.price_min..feature.price_max).include?(scrape.price)
    end

    matches
  end
end
