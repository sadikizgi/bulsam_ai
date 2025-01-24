class UpdateCarScrapeStatusesJob < ApplicationJob
  queue_as :default

  def perform
    # public_date'i 24 saatten eski ve hala is_new true olan araçları bul
    CarScrape.where(is_new: true)
             .where('public_date < ?', 24.hours.ago)
             .find_each do |car|
      car.update_columns(
        is_new: false,
        is_replay: false
      )
    end
  end
end
