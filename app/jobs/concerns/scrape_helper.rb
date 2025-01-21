module ScrapeHelper
  extend ActiveSupport::Concern

  COMMON_HEADERS = {
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
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
    'DNT' => '1'
  }

  def formatted_proxies
    proxies = Proxy.all
    # Her proxy kaydını uygun formata dönüştürüp bir diziye atıyoruz
    formatted_proxies = proxies.map do |proxy|
      [
        "http://#{proxy.ip}:#{proxy.port}", # Proxy URL'si
        proxy.username,                    # Kullanıcı adı
        proxy.password                     # Şifre
      ]
    end
    return formatted_proxies
  end

  def get_httpparty_with_proxy
    @proxies = formatted_proxies
    @proxies2 = []
    @count = @proxies.count
    proxy = @proxies[rand(@count)]
    proxy_host = proxy[0].gsub("http://","").split(":").first
    proxy_port = proxy[0].gsub("http://","").split(":").last
    HTTParty::Basement.http_proxy(proxy_host, proxy_port, proxy[1], proxy[2])
    return proxy
  end

  def simulate_human_behavior
    # Rastgele bekleme süreleri (saniye)
    sleep(rand(2.0..5.0))
  end

  def rotate_user_agent
    [
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0'
    ].sample
  end

  def setup_browser_session
    session = Mechanize.new
    session.user_agent = rotate_user_agent
    session.history.max_size = 2
    session.verify_mode = OpenSSL::SSL::VERIFY_NONE
    session.follow_meta_refresh = true
    session.keep_alive = false
    session.open_timeout = 30
    session.read_timeout = 30
    
    # Cookie yönetimi
    session.cookie_jar.clear!
    
    # Tarayıcı özellikleri
    session.pre_connect_hooks << lambda { |_, options|
      options[:headers] = COMMON_HEADERS.merge({
        'User-Agent' => session.user_agent
      })
    }
    
    session
  end

  def handle_captcha(page)
    # Nokogiri dökümanında captcha veya gizlilik kontrolü
    page_text = page.to_s.downcase
    return false unless page_text.include?('captcha') || page_text.include?('gizliliği')
    
    Rails.logger.info "Captcha detected, rotating proxy and session..."
    
    # Mevcut proxy'yi engelliler listesine al
    if @current_proxy
      @current_proxy.mark_site_as_blocked!(self.class::SITE)
      @current_proxy.update(status: 'blocked')
    end
    
    # Yeni bir proxy al ve session'ı yenile
    simulate_human_behavior
    true
  end

  def fetch_with_retry(url, max_attempts = 3)
    attempts = 0
    
    while attempts < max_attempts
      begin
        session = setup_browser_session
        
        # Ana sayfayı ziyaret et
        simulate_human_behavior
        home_page = session.get(self.class::SITE == 'arabam.com' ? 'https://www.arabam.com' : 'https://www.sahibinden.com')
        
        # Rastgele kategorileri ziyaret et
        random_links = home_page.links.select { |l| l.href =~ /kategori|otomobil|listing/ }.sample(2)
        random_links.each do |link|
          simulate_human_behavior
          session.click(link)
        end
        
        # Hedef URL'yi ziyaret et
        simulate_human_behavior
        page = session.get(url)
        
        # Sayfanın HTML içeriğini UTF-8'e çevir ve parse et
        html_content = page.content.force_encoding('UTF-8')
        parsed_page = Nokogiri::HTML(html_content)
        
        return parsed_page unless handle_captcha(parsed_page)
        
      rescue Encoding::CompatibilityError => e
        Rails.logger.error "Encoding error: #{e.message}"
        next
      rescue => e
        Rails.logger.error "Fetch error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
      
      attempts += 1
      simulate_human_behavior
    end
    
    nil
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

  def with_proxy_retry
    begin
      @current_proxy = Proxy.get_next_available(site: self.class::SITE, proxy_type: 'datacenter')
      raise 'No proxy available' unless @current_proxy
      
      start_time = Time.current
      yield
      response_time = ((Time.current - start_time) * 1000).to_i # ms cinsinden
      
      @current_proxy.record_success!(response_time)
      @current_proxy.mark_site_as_working!(self.class::SITE)
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
      @current_proxy.mark_site_as_blocked!(self.class::SITE) if blocked_error?(error)
    end
    @retry_count += 1
  end

  def should_retry?
    @retry_count < self.class::MAX_RETRIES
  end

  def blocked_error?(error)
    error.message.include?('blocked') || 
    error.message.include?('captcha') || 
    error.message.include?('rate limit')
  end
end 