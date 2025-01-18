require 'selenium-webdriver'

tracking = CarTracking.last
puts "Son tracking: #{tracking.inspect}"

sprint = Sprint.create!(
  car_tracking: tracking,
  company: tracking.category.company
)
puts "Sprint oluşturuldu: #{sprint.inspect}"

urls = tracking.websites.map { |site| 
  case site
  when "arabam"
    tracking.category.url
  end
}.compact

puts "URLs: #{urls.inspect}"

driver = Selenium::WebDriver.for :chrome
driver.get(urls.first)
sleep 2

total_pages = driver.find_elements(css: ".pagination li").count
puts "Toplam sayfa: #{total_pages}"

(1..total_pages).each do |page|
  items = driver.find_elements(css: ".listing-item")
  items.each do |item|
    begin
      title = item.find_element(css: ".listing-title h3").text
      price = item.find_element(css: ".listing-price").text.gsub(/[^\d]/, "").to_i
      km = item.find_element(css: ".listing-km").text.gsub(/[^\d]/, "").to_i
      year = item.find_element(css: ".listing-year").text.to_i
      color = item.find_element(css: ".listing-color").text
      city = item.find_element(css: ".listing-location").text
      image = item.find_element(css: ".listing-image img").attribute("src")
      url = item.find_element(css: "a.listing-link").attribute("href")

      CarScrape.create!(
        sprint: sprint,
        title: title,
        price: price,
        km: km,
        year: year,
        color: color,
        city: city,
        image_url: image,
        product_url: url,
        domain: "arabam.com"
      )
      puts "Araç kaydedildi: #{title}"
    rescue => e
      puts "Hata: #{e.message}"
    end
  end

  next_button = driver.find_elements(css: ".pagination .next").first
  break unless next_button&.enabled?
  next_button.click
  sleep 2
end

driver.quit
puts "İşlem tamamlandı" 