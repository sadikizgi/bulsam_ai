class ScrapeArabamMainJob < ApplicationJob
  queue_as :default

  USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0'
  ]

  def perform(url, category)
    puts "\n========== STARTING ARABAM.COM SCRAPER =========="
    puts "URL: #{url}"
    puts "Category: #{category}"
    puts "Time: #{Time.current}"
    puts "================================================="

    @base_url = url
    @current_page = 1
    @max_retries = 3
    @retry_delay = 2
    @total_items_processed = 0
    @total_items_saved = 0
    @scraper_user = User.find_or_create_by!(email: 'scraper@bulsam.ai') do |user|
      user.password = SecureRandom.hex(10)
      user.password_confirmation = user.password
    end

    begin
      scrape_all_pages(category)
    rescue StandardError => e
      puts "\n❌ ERROR: Job failed with error: #{e.message}"
      puts e.backtrace[0..5]
      raise
    end

    puts "\n✅ JOB COMPLETED"
    puts "Total pages processed: #{@current_page}"
    puts "Total items processed: #{@total_items_processed}"
    puts "Total items saved: #{@total_items_saved}"
    puts "================================================="
  end

  private

  def scrape_all_pages(category)
    loop do
      page_url = build_page_url
      puts "\n📄 Processing page #{@current_page}: #{page_url}"
      
      page = fetch_page(page_url)
      break unless page && has_items?(page)

      items_count = process_page(page, category)
      puts "✓ Page #{@current_page} completed - #{items_count} items processed"
      
      @current_page += 1
      sleep(rand(1.0..2.0)) # Random delay between pages
    end
  end

  def build_page_url
    if @current_page == 1
      @base_url
    else
      "#{@base_url}?page=#{@current_page}"
    end
  end

  def fetch_page(url)
    retries = 0
    begin
      agent = setup_mechanize
      puts "🌐 Fetching page with user agent: #{agent.user_agent.split.last}"
      page = agent.get(url)
      puts "✓ Page fetched successfully"
      page
    rescue StandardError => e
      retries += 1
      puts "⚠️ Error fetching page: #{e.message}"
      if retries <= @max_retries
        puts "Retry #{retries}/#{@max_retries} for #{url}"
        sleep(@retry_delay * retries)
        retry
      else
        puts "❌ Failed to fetch page after #{@max_retries} retries"
        return nil
      end
    end
  end

  def setup_mechanize
    agent = Mechanize.new
    agent.user_agent = USER_AGENTS.sample
    agent.history.max_size = 1
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    agent.open_timeout = 10
    agent.read_timeout = 10
    agent
  end

  def has_items?(page)
    return false unless page
    items = page.search('.listing-list-item')
    puts "📊 Found #{items.length} items on current page"
    !items.empty?
  end

  def process_page(page, category)
    items_processed = 0
    page.search('.listing-list-item').each do |item|
      puts "\n🔄 Processing item #{items_processed + 1}..."
      begin
        item_data = extract_item_data(item)
        item_data[:category] = category
        save_or_update_item(item_data, category)
        items_processed += 1
        @total_items_processed += 1
      rescue StandardError => e
        puts "⚠️ Error processing item: #{e.message}"
      end
    end
    items_processed
  end

  def extract_item_data(item)
    puts "📝 Extracting item data..."
    
    title_element = item.at('.listing-text h3')
    title_text = title_element&.text&.strip
    puts "Title: #{title_text}"
    
    title_parts = title_text&.split(' ')
    price_text = item.at('.listing-price')&.text
    puts "Price: #{price_text}"
    
    location = item.at('.listing-location')&.text&.strip
    puts "Location: #{location}"
    
    external_id = item.at('a')['href']&.split('/')&.last
    puts "External ID: #{external_id}"
    
    {
      brand: title_parts&.first,
      model: title_parts&.[](1..-1)&.join(' '),
      year: extract_year(title_text),
      price: extract_price(price_text),
      location: location,
      external_id: external_id,
      mileage: extract_mileage(item.at('.listing-text')&.text),
      fuel_type: extract_fuel_type(item.at('.listing-text')&.text),
      transmission: extract_transmission(item.at('.listing-text')&.text),
      status: 'tracking'
    }
  end

  def extract_year(title_text)
    return nil unless title_text
    year = title_text.match(/\b(19|20)\d{2}\b/)&.[](0)&.to_i
    puts "Year: #{year}"
    year
  end

  def extract_price(price_text)
    return nil unless price_text
    price = price_text.gsub(/[^\d]/, '').to_i
    puts "Price: #{price}"
    price
  end

  def extract_mileage(text)
    return 0 unless text
    mileage = text.match(/(\d+(?:,\d+)?)\s*km/i)&.[](1)&.gsub(',', '')&.to_i || 0
    puts "Mileage: #{mileage}"
    mileage
  end

  def extract_fuel_type(text)
    return 'gasoline' unless text
    fuel_type = case text.downcase
    when /dizel/
      'diesel'
    when /benzin/
      'gasoline'
    when /lpg/
      'lpg'
    when /hibrit/
      'hybrid'
    when /elektrik/
      'electric'
    else
      'gasoline'
    end
    puts "Fuel Type: #{fuel_type}"
    fuel_type
  end

  def extract_transmission(text)
    return 'manual' unless text
    transmission = case text.downcase
    when /otomatik/
      'automatic'
    when /manuel/
      'manual'
    when /yarı otomatik/
      'semi_automatic'
    else
      'manual'
    end
    puts "Transmission: #{transmission}"
    transmission
  end

  def save_or_update_item(item_data, category)
    case category
    when 'car'
      save_or_update_car(item_data)
    when 'property'
      save_or_update_property(item_data)
    end
  end

  def save_or_update_car(data)
    puts "\n💾 Saving/Updating car with external_id: #{data[:external_id]}"
    car = Car.find_or_initialize_by(external_id: data[:external_id])
    
    if car.update(
      brand: data[:brand],
      model: data[:model],
      year: data[:year],
      price: data[:price],
      mileage: data[:mileage],
      fuel_type: data[:fuel_type],
      transmission: data[:transmission],
      location: data[:location],
      status: data[:status],
      user: @scraper_user
    )
      puts "✓ Car saved successfully"
      @total_items_saved += 1
    else
      puts "❌ Failed to save car"
      puts "Errors: #{car.errors.full_messages}"
    end
  end

  def save_or_update_property(data)
    puts "\n💾 Saving/Updating property with external_id: #{data[:external_id]}"
    property = Property.find_or_initialize_by(external_id: data[:external_id])
    
    if property.update(
      title: data[:title],
      price: data[:price],
      location: data[:location],
      date_posted: data[:date_posted],
      details_url: data[:details_url],
      image_url: data[:image_url]
    )
      @total_items_saved += 1
      puts "✅ Property saved successfully"
      puts property.attributes
    else
      puts "❌ Failed to save property"
      puts "Errors: #{property.errors.full_messages}"
    end
  end
end
