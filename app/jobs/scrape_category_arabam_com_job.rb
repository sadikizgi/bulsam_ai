class ScrapeCategoryArabamComJob < ApplicationJob
  queue_as :default
  
  SITE = 'arabam.com'
  MAX_RETRIES = 3

  def perform(*args)
    require 'webrick/httputils'
    require 'addressable/uri'
    require 'nokogiri'
    require 'net/http'
    require 'open-uri'
    require 'uri'

    Rails.logger.info "Starting ScrapeCategoryArabamComJob"

    @company = Company.find 1
    @sprint =  @company.sprints.new
    @sprint.domain = "arabam.com"
    @sprint.sidekiq_name = "ScrapeCategoryArabamComJob"
    @sprint.save

    Rails.logger.info "Created/Found sprint: #{@sprint.id}"

    @user_agent = ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3080.30 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36", 
                   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36", 
                   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"]
    agent = @user_agent[rand(@user_agent.count)]
    
    @retry_count = 0
    @current_proxy = nil

    products = []
    link = "https://www.arabam.com/ikinci-el"
    
    with_proxy_retry do
      page_html = fetch_html(link, agent)
      page_html.css(".category-facet")[0].css("ul")[0].css("li").each do |item|
        category_name = item.css("a").text.strip.split("\r").first
        category_url = "https://www.arabam.com" + item.css("a").first["href"]
        category = Category.find_or_create_by(name: category_name, category_url: category_url, company_id: @company.id)
        category.save
        Rails.logger.info "Created/Found category: #{category.id}"

        with_proxy_retry do
          category_page_html = fetch_html(category_url, agent)
          if category_page_html.css(".category-facet").present? && category_page_html.css(".category-facet").css("ul").last.css("li").count > 0
            category_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
              brand_name = item.css("a").text.strip.split("\r").first
              brand_url = "https://www.arabam.com" + item.css("a").first["href"]
              brand = Brand.find_or_create_by(name: brand_name, brand_url: brand_url, category_id: category.id)
              brand.save
              Rails.logger.info "Created/Found brand: #{brand.id}"

              with_proxy_retry do
                model_page_html = fetch_html(brand_url, agent)
                if model_page_html.css(".category-facet").present? && model_page_html.css(".category-facet").css("ul").last.css("li").count > 0
                  model_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
                    model_name = item.css("a").text.strip.split("\r").first
                    model_url = "https://www.arabam.com" + item.css("a").first["href"]
                    model = Model.find_or_create_by(name: model_name, model_url: model_url, brand_id: brand.id)
                    model.save
                    Rails.logger.info "Created/Found model: #{model.id}"

                    with_proxy_retry do
                      serials_page_html = fetch_html(model_url, agent)
                      if serials_page_html.css(".category-facet").present? && serials_page_html.css(".category-facet").css("ul").last.css("li").count > 0
                        serials_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
                          serial_name = item.css("a").text.strip.split("\r").first
                          serial_url = "https://www.arabam.com" + item.css("a").first["href"]
                          serial = Serial.find_or_create_by(name: serial_name, serial_url: serial_url, model_id: model.id, engine_size: serial_name)
                          serial.save
                          Rails.logger.info "Created/Found serial: #{serial.id}"
                        end
                      end 
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    Rails.logger.info "Found #{products.count} categories"
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

  def fetch_html(url, agent)
    attempts = 0
    begin
      attempts += 1
      uri = URI(normalize_uri(url))
      
      http = Net::HTTP.new(uri.host, uri.port, @current_proxy&.ip, @current_proxy&.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = agent
      
      if @current_proxy&.username.present?
        request.basic_auth(@current_proxy.username, @current_proxy.password)
      end
      
      response = http.request(request)
      Nokogiri::HTML(response.body, nil, "UTF-8")
    rescue => e
      puts "Hata: #{e.message} (Deneme: #{attempts})"
      retry if attempts < MAX_RETRIES
      nil
    end
  end

  def normalize_uri(uri)
    uri = uri.to_s
    Addressable::URI.parse(uri).normalize.to_s
  end
end
