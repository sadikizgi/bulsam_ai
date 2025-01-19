class ScrapeArabamMainJob < ApplicationJob
  queue_as :default

  SITE = 'arabam.com'
  MAX_RETRIES = 3

  def perform(links, sprint_id)
    require 'open-uri'
    require 'nokogiri'
    require 'webrick/httputils'
    require 'net/http'

    Rails.logger.info "Starting ScrapeArabamMainJob"

    @sprint = Sprint.find(sprint_id)
    @company = @sprint.company
    @retry_count = 0
    @current_proxy = nil

    Rails.logger.info "Using sprint: #{@sprint.id}"

    @user_agent = ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3080.30 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36", 
                   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"]
    agent = @user_agent[rand(@user_agent.count)]

    products = []

    links.each do |link|
      with_proxy_retry do
        process_link(link)
      end
    end

    Rails.logger.info "Found #{products.count} products to save"

    products.each do |product|
      begin
        save_scrap(product)
      rescue StandardError => error
        Rails.logger.error "Error saving product #{product[:link]}: #{error.message}"
        create_issue(error.message, product[:link])
      end
    end

    @sprint.update!(completed_at: Time.zone.now)
    Rails.logger.info "Job completed successfully"

    remove_instance_variable(:@sprint)
    remove_instance_variable(:@company)
    remove_instance_variable(:@user_agent)
  end

  private

  def with_proxy_retry
    begin
      @current_proxy = Proxy.get_next_available(site: SITE, proxy_type: 'datacenter')
      raise 'No proxy available' unless @current_proxy
      
      start_time = Time.current
      yield
      response_time = ((Time.current - start_time) * 1000).to_i # ms cinsinden
      
      @current_proxy.record_success!(response_time)
      @current_proxy.mark_site_as_working!(SITE)
      @current_proxy.mark_as_used!
      
    rescue Selenium::WebDriver::Error::WebDriverError => e
      handle_proxy_error(e)
      retry if should_retry?
      raise
    rescue StandardError => e
      handle_proxy_error(e)
      retry if should_retry?
      raise
    end
  end

  def handle_proxy_error(error)
    if @current_proxy
      @current_proxy.record_error!(error.message)
      @current_proxy.mark_site_as_blocked!(SITE) if blocked_error?(error)
    end
    @retry_count += 1
  end

  def should_retry?
    @retry_count < MAX_RETRIES
  end

  def blocked_error?(error)
    error.message.include?('blocked') || 
    error.message.include?('captcha') || 
    error.message.include?('rate limit')
  end

  def process_link(link)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument("--proxy-server=#{@current_proxy.url}") if @current_proxy
    
    driver = Selenium::WebDriver.for :chrome, options: options
    
    begin
      driver.get(link)
      doc = Nokogiri::HTML(driver.page_source, nil, "UTF-8")
      page_count = (doc.css("#top-bar").css("#js-hook-for-advert-count").text.to_i/20)+1

      Rails.logger.info "Found #{page_count} pages to process"

      doc.css("#main-listing").css(".listing-list-item").each do |item|
        product = parse_product(item)
        products << product if product
      end

      (2..page_count).each do |paginate|
        page_url = link + "?page=" + paginate.to_s
        Rails.logger.info "Processing page: #{page_url}"
        
        driver.get(page_url)
        doc = Nokogiri::HTML(driver.page_source, nil, "UTF-8")
        
        doc.css("#main-listing").css(".listing-list-item").each do |item|
          product = parse_product(item)
          products << product if product
        end
      end
    ensure
      driver.quit
    end
  end

  def parse_product(item)
    {
      link: "https://www.arabam.com/" + item.css("td")[0].css("a").first["href"],
      img: item.css("td")[0].css("a").first.css("img").first["data-src"],
      name: item.css("td")[1].css(".listing-text-new").text,
      description: item.css("td")[2].css("h4").text.strip,
      year: item.css("td")[3].text.strip,
      km: item.css("td")[4].text.strip,
      color: item.css("td")[5].text.strip,
      price: item.css("td")[6].css(".listing-price").text.strip.split(" ")[0],
      public_date: item.css("td")[7].text.strip.to_date,
      city: item.css("td")[8].css(".fade-out-content-wrapper").text.strip.gsub(" ","").gsub("\r\n"," ")
    }
  rescue StandardError => e
    Rails.logger.error "Error parsing product: #{e.message}"
    nil
  end

  def save_scrap(product)
    existing_scrape = CarScrape.find_by(
      product_url: product[:link],
      sprint: @sprint
    )
    
    @scrap = existing_scrape || @sprint.car_scrapes.new
    @scrap.is_new = !existing_scrape
    
    @scrap.assign_attributes(
      title: product[:description],
      price: product[:price],
      km: product[:km],
      year: product[:year],
      color: product[:color],
      city: product[:city],
      image_url: product[:img],
      product_url: product[:link],
      public_date: product[:public_date]
    )
    
    @scrap.save!
  end

  def create_issue(message, url)
    @issue = @sprint.scrap_issues.new(
      error_message: message,
      url: url
    )
    @issue.save
    remove_instance_variable(:@issue)
  rescue StandardError => e
    Rails.logger.error "Error creating issue: #{e.message}"
  end
end
