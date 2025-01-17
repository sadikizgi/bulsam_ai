class ScrapeDeneneDenemeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    require 'open-uri'
    require 'nokogiri'
    require 'webrick/httputils'
    require 'net/http'

    Rails.logger.info "Starting ScrapeDeneneDenemeJob"

    @company = Company.find 1
    @sprint =  @company.sprints.new
    @sprint.domain = "arabam.com"
    @sprint.sidekiq_name = "ScrapeDeneneDenemeJob"
    @sprint.save

    Rails.logger.info "Created/Found sprint: #{@sprint.id}"

    @user_agent = ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3080.30 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36", 
                   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"]
    agent = @user_agent[rand(@user_agent.count)]

    products = []
    links = ["https://www.arabam.com/ikinci-el/otomobil/volkswagen-polo-1-0", 
             "https://www.arabam.com/ikinci-el/otomobil/volkswagen-arteon"]

    links.each do |link|
      Rails.logger.info "Processing link: #{link}"
      begin
        doc = URI.open(link, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
        page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
        page_count = (page_html.css("#top-bar").css("#js-hook-for-advert-count").text.to_i/20)+1

        Rails.logger.info "Found #{page_count} pages to process"

        page_html.css("#main-listing").css(".listing-list-item").each do |item|
          product = parse_product(item)
          products << product if product
        end

        (2..page_count).each do |paginate|
          page_url = link + "?page=" + paginate.to_s
          Rails.logger.info "Processing page: #{page_url}"
          
          doc = URI.open(page_url, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
          
          page_html.css("#main-listing").css(".listing-list-item").each do |item|
            product = parse_product(item)
            products << product if product
          end
        end
      rescue StandardError => e
        Rails.logger.error "Error processing link #{link}: #{e.message}"
        create_issue(e.message, link)
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
    @scrap = @sprint.car_scrapes.new
    
    @scrap.product_url = product[:link]
    @scrap.currency = "₺"
    @scrap.domain = "arabam.com"
    @scrap.price = product[:price].gsub(".", "").to_i
    @scrap.year = product[:year].gsub(".", "").to_i
    @scrap.km = product[:km].gsub(".", "").to_i
    @scrap.color = product[:color]
    @scrap.name = product[:name]
    @scrap.title = product[:description]
    @scrap.image_url = product[:img]
    @scrap.city = product[:city]
    @scrap.public_date = product[:public_date]
    
    unless @scrap.save
      Rails.logger.error "Save error: #{@scrap.errors.full_messages}"
      raise "Failed to save scrap: #{@scrap.errors.full_messages}"
    end

    Rails.logger.info "Saved scrap: #{@scrap.id}"
    remove_instance_variable(:@scrap) if @scrap.present?
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
