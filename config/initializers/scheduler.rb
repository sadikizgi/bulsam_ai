require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

# En sık kontrol süresi olan 30 dakikada bir çalıştır
scheduler.every '30m' do
  UpdateCarScrapesJob.perform_later
end 