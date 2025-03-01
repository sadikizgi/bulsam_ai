# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "log/cron_log.log"

every 1.hour do
  runner "ScrapeArabamMainJob.perform_later"
end

every 30.minutes do
  runner "ManageNewCarScrapesJob.perform_later"
end

every 10.minutes do
  runner "SendNewCarNotificationsJob.perform_later"
end

# Her saat başı araç durumlarını güncelle
every 1.hour do
  runner "UpdateCarScrapeStatusesJob.perform_later"
end 