class UpdateCarScrapesJob < ApplicationJob
  queue_as :default

  def perform
    # Her bir takip için kontrol et
    CarTracking.find_each do |tracking|
      next unless should_check?(tracking)

      # Son kontrol zamanından sonra eklenen ve filtrelere uyan araçları bul
      new_scrapes = tracking.car_scrapes
                           .where('created_at > ?', last_check_time(tracking))
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

  def should_check?(tracking)
    return true unless tracking.car_tracking_feature&.notification_frequency

    last_check = tracking.car_scrapes.maximum(:created_at) || tracking.created_at
    frequency = parse_frequency(tracking.car_tracking_feature.notification_frequency)
    
    Time.current - last_check >= frequency
  end

  def last_check_time(tracking)
    frequency = parse_frequency(tracking.car_tracking_feature&.notification_frequency || '1h')
    frequency.ago
  end

  def parse_frequency(frequency)
    value = frequency[0..-2].to_i
    unit = frequency[-1]
    
    case unit
    when 'm' then value.minutes
    when 'h' then value.hours
    when 'd' then value.days
    when 'w' then value.weeks
    else 1.hour # varsayılan
    end
  end

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
