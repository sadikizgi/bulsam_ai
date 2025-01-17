require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

scheduler.every '1h' do
  UpdateCarScrapesJob.perform_later
end 