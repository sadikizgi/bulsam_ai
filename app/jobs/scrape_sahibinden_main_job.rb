class ScrapeSahibindenMainJob < ApplicationJob
  queue_as :default
  
  SITE = 'sahibinden.com'
  MAX_RETRIES = 3

  include ScrapeHelper

  USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Edge/120.0.0.0'
  ]

  def perform(url, category = nil)
    @base_url = url
    @category = category
    @current_page = 1
    @retry_count = 0
    @current_proxy = nil
    @retry_delay = 10
    @agent = setup_mechanize
    @cookies = {}

    begin
      scrape_all_pages
    rescue StandardError => e
      Rails.logger.error "Scraping error: #{e.message}"
      retry_job wait: (@retry_delay * @current_page).seconds if @current_page < MAX_RETRIES
    end
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

  def setup_mechanize
    agent = Mechanize.new
    agent.user_agent = USER_AGENTS.sample
    agent.history.max_size = 1
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    agent.follow_meta_refresh = true
    agent.keep_alive = false
    agent.open_timeout = 60
    agent.read_timeout = 60
    
    # Proxy kullan
    if @current_proxy
      agent.set_proxy(@current_proxy.ip, @current_proxy.port, @current_proxy.username, @current_proxy.password)
    end
    
    # Tarayıcı benzeri davranış
    agent.pre_connect_hooks << lambda { |_, options|
      options[:headers] = {
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language' => 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding' => 'gzip, deflate, br',
        'Cache-Control' => 'max-age=0',
        'Sec-Ch-Ua' => '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'Sec-Ch-Ua-Mobile' => '?0',
        'Sec-Ch-Ua-Platform' => '"macOS"',
        'Sec-Fetch-Dest' => 'document',
        'Sec-Fetch-Mode' => 'navigate',
        'Sec-Fetch-Site' => 'none',
        'Sec-Fetch-User' => '?1',
        'Upgrade-Insecure-Requests' => '1',
        'Connection' => 'keep-alive',
        'Cookie' => format_cookies
      }
    }

    agent
  end

  def format_cookies
    @cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
  end

  def update_cookies(page)
    page.response['Set-Cookie']&.split(',')&.each do |cookie_str|
      if cookie_str =~ /^([^=]+)=([^;]+)/
        @cookies[$1] = $2
      end
    end
  end

  def scrape_all_pages
    loop do
      with_proxy_retry do
        page_url = build_page_url
        page_data = fetch_page(page_url)
        
        break unless page_data && has_items?(page_data)
        
        process_page(page_data)
        @current_page += 1
        
        # Daha gerçekçi bekleme süreleri
        sleep(rand(5..15))
      end
    end
  end

  def build_page_url
    offset = (@current_page - 1) * 20
    offset.zero? ? @base_url : "#{@base_url}?pagingOffset=#{offset}"
  end

  def fetch_page(url)
    begin
      # İlk sayfa için ekstra işlemler
      if @current_page == 1
        # Önce ana sayfayı ziyaret et
        home_page = @agent.get('https://www.sahibinden.com/')
        update_cookies(home_page)
        
        # Rastgele kategorileri ziyaret et
        random_categories = home_page.links.select { |l| l.href =~ /kategori/ }.sample(2)
        random_categories.each do |category|
          page = @agent.click(category)
          update_cookies(page)
          sleep(rand(3..7))
        end
        
        sleep(rand(4..8))
      end
      
      # Hedef sayfaya git
      page = @agent.get(url)
      update_cookies(page)
      
      if page.code == '200'
        page
      else
        Rails.logger.error "Failed to fetch page: #{page.code}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching page: #{e.message}"
      @agent = setup_mechanize
      nil
    end
  end

  def has_items?(page)
    !page.search('.searchResultsRowClass').empty?
  end

  def process_page(page)
    items = page.search('.searchResultsRowClass tr')
    
    items.each do |item|
      begin
        data = extract_item_data(item)
        save_or_update_item(data) if data
        sleep(rand(0.5..1.5)) # Her öğe arasında küçük gecikmeler
      rescue StandardError => e
        Rails.logger.error "Error processing item: #{e.message}"
        next
      end
    end
  end

  def extract_item_data(item)
    {
      title: item.at('.classifiedTitle')&.text&.strip,
      price: extract_price(item.at('.classified-price-container')&.text),
      location: item.at('.cityArea')&.text&.strip,
      date_posted: item.at('.date')&.text&.strip,
      details_url: "https://www.sahibinden.com#{item.at('.classifiedTitle')&.attribute('href')&.value}",
      image_url: item.at('.searchImage img')&.attribute('src')&.value,
      category: @category,
      external_id: item['data-id']
    }
  end

  def extract_price(price_text)
    return 0 unless price_text
    price_text.gsub(/[^\d]/, '').to_i
  end

  def save_or_update_item(data)
    case @category
    when 'car'
      save_or_update_car(data)
    when 'property'
      save_or_update_property(data)
    end
  end

  def save_or_update_car(data)
    # Önce external_id ile kontrol et
    car = CarScrape.find_by(external_id: data[:external_id], sprint: @sprint)
    
    # Eğer external_id ile bulunamadıysa, diğer özelliklere göre kontrol et
    if !car
      car = @sprint.car_scrapes.find_by(
        title: data[:title],
        price: data[:price],
        city: data[:location],
        product_url: data[:details_url]
      )
    end
    
    # Eğer hala bulunamadıysa yeni kayıt oluştur
    car ||= @sprint.car_scrapes.new
    
    # İlk tarama değilse ve yeni bir kayıtsa is_new true olsun
    car.is_new = !car.persisted? && !@sprint.car_tracking.sprints.one?
    
    car.update!(
      title: data[:title],
      price: data[:price],
      city: data[:location],
      public_date: data[:date_posted],
      product_url: data[:details_url],
      image_url: data[:image_url],
      external_id: data[:external_id]
    )
  end

  def save_or_update_property(data)
    property = Property.find_or_initialize_by(external_id: data[:external_id])
    
    property.update!(
      title: data[:title],
      price: data[:price],
      location: data[:location],
      listing_date: data[:date_posted],
      details_url: data[:details_url],
      image_url: data[:image_url]
    )
  end
end
