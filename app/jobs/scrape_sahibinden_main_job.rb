class ScrapeSahibindenMain < ApplicationJob
  queue_as :default
  
  PROXY_LIST = [
    # Buraya proxy listesi eklenebilir
    # örnek: "http://proxy1.example.com:8080"
  ]

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59'
  ]

  def perform(url, category = nil)
    @base_url = url
    @category = category
    @current_page = 1
    @max_retries = 3
    @retry_delay = 5 # seconds

    begin
      scrape_all_pages
    rescue StandardError => e
      Rails.logger.error "Scraping error: #{e.message}"
      retry_job wait: @retry_delay.seconds if @current_page < @max_retries
    end
  end

  private

  def scrape_all_pages
    loop do
      page_url = build_page_url
      page_data = fetch_page(page_url)
      
      break unless page_data && has_items?(page_data)
      
      process_page(page_data)
      @current_page += 1
      
      # Rate limiting
      sleep(rand(2..5))
    end
  end

  def build_page_url
    offset = (@current_page - 1) * 20
    offset.zero? ? @base_url : "#{@base_url}?pagingOffset=#{offset}"
  end

  def fetch_page(url)
    retries = 0
    begin
      response = HTTParty.get(
        url,
        headers: {
          'User-Agent' => USER_AGENTS.sample,
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Connection' => 'keep-alive',
          'Upgrade-Insecure-Requests' => '1',
          'Cache-Control' => 'max-age=0'
        },
        proxy: PROXY_LIST.sample
      )
      
      if response.code == 200
        Nokogiri::HTML(response.body)
      else
        Rails.logger.error "Failed to fetch page: #{response.code}"
        nil
      end
    rescue StandardError => e
      retries += 1
      if retries < @max_retries
        sleep(@retry_delay)
        retry
      else
        Rails.logger.error "Max retries reached: #{e.message}"
        nil
      end
    end
  end

  def has_items?(page)
    !page.css('.searchResultsRowClass').empty?
  end

  def process_page(page)
    items = page.css('.searchResultsRowClass tr')
    
    items.each do |item|
      begin
        data = extract_item_data(item)
        save_or_update_item(data) if data
      rescue StandardError => e
        Rails.logger.error "Error processing item: #{e.message}"
        next
      end
    end
  end

  def extract_item_data(item)
    {
      title: item.css('.classifiedTitle').text.strip,
      price: extract_price(item.css('.classified-price-container').text),
      location: item.css('.cityArea').text.strip,
      date_posted: item.css('.date').text.strip,
      details_url: "https://www.sahibinden.com#{item.css('.classifiedTitle').attr('href')&.value}",
      image_url: item.css('.searchImage img').attr('src')&.value,
      category: @category,
      external_id: item['data-id']
    }
  end

  def extract_price(price_text)
    # Fiyat metninden sayısal değeri çıkar
    price_text.gsub(/[^\d]/, '').to_i
  end

  def save_or_update_item(data)
    # Bu kısım modele göre düzenlenecek
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
