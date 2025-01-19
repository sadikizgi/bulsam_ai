class ScrapeArabamMainJob < ApplicationJob
  queue_as :default

  SITE = 'arabam.com'
  MAX_RETRIES = 3
  MAX_PAGES = 15

  def perform(links, sprint_id)
    require 'open-uri'
    require 'nokogiri'
    require 'webrick/httputils'
    require 'net/http'

    Rails.logger.info "Starting ScrapeArabamMainJob"

    @sprint = Sprint.find(sprint_id)
    @company = @sprint.company
    proxies = Proxy.all
    # Her proxy kaydını uygun formata dönüştürüp bir diziye atıyoruz
    formatted_proxies = proxies.map do |proxy|
      [
        "http://#{proxy.ip}:#{proxy.port}", # Proxy URL'si
        proxy.username,                    # Kullanıcı adı
        proxy.password                     # Şifre
      ]
    end
    @proxies = formatted_proxies
    @count = @proxies.count
    @proxies2 = []
    
    @user_agent = ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3080.30 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36", 
                   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"]

    products = []

    links.each do |link|
      process_link(link, products)
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
  end

  private

  def process_link(link, products)
    paginate = 1
    while paginate != 0 && paginate <= MAX_PAGES
      begin
        check = true
        proxy_error_count = 0

        while check
          agent = @user_agent[rand(@user_agent.count)]
          proxy = @proxies[rand(@count)]

          begin
            check = false
            sleep 2
            Rails.logger.info "Processing page #{paginate} of #{link}"
            
            page_url = fetch_page(link, paginate, agent, proxy)
            
            if page_url.css("#main-listing").css(".listing-list-item").present?
              page_url.css("#main-listing").css(".listing-list-item").each do |item|
                product = parse_product(item)
                products << product if product
              end
              paginate += 1
            else
              paginate = 0
            end

          rescue => error
            Rails.logger.error "Proxy error: #{error.message}"
            Rails.logger.error "Agent: #{agent}"
            Rails.logger.error "Proxy: #{proxy}"
            
            proxy_error_count += 1
            @count -= 1
            
            index = @proxies.index { |x| x[0] == proxy[0].to_s }
            @proxies.delete_at(index) if index
            @proxies2 << proxy
            
            if @proxies.count == 0
              @proxies = @proxies2
              @count = @proxies2.count
            end

            if proxy_error_count == MAX_RETRIES
              create_issue(error.message, link, agent, proxy)
              check = false
            else
              check = true
              Rails.logger.info "Retrying with different proxy. Remaining proxies: #{@proxies.count}"
            end
          end
        end

      rescue => error
        Rails.logger.error "Error processing page: #{error.message}"
        paginate = 0
      end
    end
  end

  def fetch_page(link, paginate, agent, proxy)
    url = paginate == 1 ? link : "#{link}?page=#{paginate}"
    url = normalize_uri(url).to_s unless url_valid?(url)
    
    doc = URI.open(url, 
      'User-Agent' => agent,
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
      proxy_http_basic_authentication: proxy
    )
    
    Nokogiri::HTML(doc.read, nil, "UTF-8")
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
      price: product[:price].gsub(".","").to_i  ,
      km: product[:km].gsub(".","").to_i,
      year: product[:year],
      color: product[:color],
      city: product[:city],
      image_url: product[:img],
      product_url: product[:link],
      public_date: product[:public_date]
    )
    
    @scrap.save!
  end

  def create_issue(error_message, url, agent = nil, proxy = nil)
    message = error_message.to_s
    message += " - user-agent: #{agent}" if agent
    message += " - proxy: #{proxy.join(',')}" if proxy
    message += " - RETRIED"

    @sprint.scrap_issues.create!(
      error_message: message,
      url: url
    )
  end

  def get_proxies_mix
    # Bu metodu kendi proxy alma mantığınıza göre implemente edin
    Proxy.active.available_for_site(SITE).map { |p| [p.ip, p.port, p.username, p.password] }
  end

  def normalize_uri(uri)
    uri = uri.to_s
    Addressable::URI.parse(uri).normalize.to_s
  end

  def url_valid?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end
