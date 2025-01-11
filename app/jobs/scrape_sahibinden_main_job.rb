class ScrapeSahibindenMainJob < ApplicationJob
  queue_as :default
  
  PROXY_LIST = [
    # Ücretsiz proxy'ler - gerçek uygulamada ücretli proxy servisleri kullanılmalı
    'http://185.162.231.167:80',
    'http://91.241.217.58:9090',
    'http://46.101.13.77:80',
    'http://51.159.115.233:3128',
    'http://178.128.200.87:80'
  ]

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
    @max_retries = 5 # Retry sayısını artırdık
    @retry_delay = 10 # Bekleme süresini artırdık
    @agent = setup_mechanize
    @cookies = {}

    begin
      scrape_all_pages
    rescue StandardError => e
      Rails.logger.error "Scraping error: #{e.message}"
      retry_job wait: (@retry_delay * @current_page).seconds if @current_page < @max_retries
    end
  end

  private

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
    if PROXY_LIST.any?
      proxy_uri = URI.parse(PROXY_LIST.sample)
      agent.set_proxy(proxy_uri.host, proxy_uri.port)
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
      page_url = build_page_url
      page_data = fetch_page(page_url)
      
      break unless page_data && has_items?(page_data)
      
      process_page(page_data)
      @current_page += 1
      
      # Daha gerçekçi bekleme süreleri
      sleep(rand(5..15))
    end
  end

  def build_page_url
    offset = (@current_page - 1) * 20
    offset.zero? ? @base_url : "#{@base_url}?pagingOffset=#{offset}"
  end

  def fetch_page(url)
    retries = 0
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
      retries += 1
      if retries < @max_retries
        # Her denemede farklı proxy ve user agent kullan
        @agent = setup_mechanize
        sleep(@retry_delay * retries + rand(1..5))
        retry
      else
        Rails.logger.error "Max retries reached: #{e.message}"
        nil
      end
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
    car = Car.find_or_initialize_by(external_id: data[:external_id])
    
    car.update!(
      title: data[:title],
      price: data[:price],
      location: data[:location],
      listing_date: data[:date_posted],
      details_url: data[:details_url],
      image_url: data[:image_url]
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
