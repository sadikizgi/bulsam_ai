class ScrapeArabamMainJob < ApplicationJob
  queue_as :default

  SITE = 'arabam.com'
  MAX_RETRIES = 15
  MAX_PAGES = 15

  def perform(links, sprint_id)
    require 'open-uri'
    require 'nokogiri'
    require 'webrick/httputils'
    require 'net/http'

    Rails.logger.info "Starting ScrapeArabamMainJob"

    @sprint = Sprint.find(sprint_id)
    @sprint.update!(domain: 'arabam.com')
    @sprint.update!(sidekiq_name: 'ScrapeArabamMainJob')
    @sprint.save
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
                   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0",
                   "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)", "YahooMailProxy; https://help.yahoo.com/kb/yahoo-mail-proxy-SLN28749.html", "check_http/v2.2.1.git (nagios-plugins 2.2.1)", "Mozilla/5.0 (compatible; MJ12bot/v1.4.5; http://www.majestic12.co.uk/bot.php?+)", "Mozilla/5.0 (compatible; MegaIndex.ru/2.0; +http://megaindex.com/crawler)", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36 RuxitSynthetic/1.0", "Mozilla/5.0 (compatible; AhrefsBot/5.2; +http://ahrefs.com/robot/)", "python-requests/2.20.1", "Pingdom.com_bot_version_1.4_(http://www.pingdom.com/)", "Apache/2.4.7 (Unix) OpenSSL/1.0.1e PHP/5.4.22 mod_perl/2.0.8-dev Perl/v5.16.3 (internal dummy connection)", "Mozilla/5.0 (X11; U; Linux Core i7-4980HQ; de; rv:32.0; compatible; JobboerseBot; http://www.jobboerse.com/bot.htm) Gecko/20100101 Firefox/38.0", "Mozilla/5.0 (compatible; SemrushBot/2~bl; +http://www.semrush.com/bot.html)", "LogicMonitor SiteMonitor/1.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.101 Safari/537.36 RuxitSynthetic/1.0", "Mozilla/5.0 (compatible; SemrushBot/1.2~bl; +http://www.semrush.com/bot.html)", "Xymon xymonnet/4.3.17", "Mozilla/5.0 (compatible; Yahoo! Slurp/3.0; http://help.yahoo.com/help/us/ysearch/slurp)", "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)", "Mozilla/5.0 (compatible; AhrefsBot/5.0; +http://ahrefs.com/robot/)", "Mozilla/5.0 (compatible; seoscanners.net/1; +spider@seoscanners.net)", "Mozilla/5.0 (compatible; spbot/5.0.3; +http://OpenLinkProfiler.org/bot )", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/534+ (KHTML, like Gecko) BingPreview/1.0b", "Mozilla/5.0 (compatible; SEOkicks-Robot; +http://www.seokicks.de/robot.html)", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.5195.125 Safari/537.36 RuxitSynthetic/1.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.115 Safari/537.36 RuxitSynthetic/1.0", "HWCDN/GFS v1.80.995-4.38.2369.el7 CDS/DA2", "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 RuxitSynthetic/1.0", "CheckMarkNetwork/1.0 (+http://www.checkmarknetwork.com/spider.html)", "Mozilla/5.0 (compatible; SeznamBot/3.2; +http://napoveda.seznam.cz/en/seznambot-intro/)", "Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0 DejaClick/2.9.7.2", "Mozilla/5.0 (compatible; AhrefsBot/5.1; +http://ahrefs.com/robot/)", "Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)"]

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
          puts "şuanki ilk proxy: #{proxy.to_s}"
          begin
            check = false
            sleep 2
            Rails.logger.info "Processing page #{paginate} of #{link}"
            
            page_url = fetch_page(link, paginate, agent)
            while page_url.text.include? "Gizliliği\r\n"
              agent = @user_agent[rand(@user_agent.count)]
              proxy = @proxies[rand(@count)]
              puts "değişecek proxy: #{proxy.to_s}"
              Rails.logger.info "Gizliliği sayfasına yönlendirildi. Yeniden deniyor..."
              sleep 2
              page_url = fetch_page(link, paginate, agent, proxy)
            end
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

  def fetch_page(link, paginate, agent)
    url = paginate == 1 ? link : "#{link}?sort=startedAt.desc&page=#{paginate}"
    url = normalize_uri(url).to_s unless url_valid?(url)
    
    doc = URI.open(url, 
      'User-Agent' => agent,
      ssl_verify_mode: 0
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
      public_date: item.css("td")[7].text.strip.gsub('Ocak', 'January')
      .gsub('Şubat', 'February')
      .gsub('Mart', 'March')
      .gsub('Nisan', 'April')
      .gsub('Mayıs', 'May')
      .gsub('Haziran', 'June')
      .gsub('Temmuz', 'July')
      .gsub('Ağustos', 'August')
      .gsub('Eylül', 'September')
      .gsub('Ekim', 'October')
      .gsub('Kasım', 'November')
      .gsub('Aralık', 'December').to_date,
      city: item.css("td")[8].css(".fade-out-content-wrapper").text.strip.gsub(" ","").gsub("\r\n"," ")
    }
  rescue StandardError => e
    Rails.logger.error "Error parsing product: #{e.message}"
    nil
  end

  def save_scrap(product)
    # Önce URL'ye göre tüm sprint'lerde kontrol et
    existing_scrape = CarScrape.find_by(product_url: product[:link])
    
    # URL ile bulunamadıysa, diğer özelliklere göre kontrol et
    if !existing_scrape
      # Sayısal değerleri temizle ve integer'a çevir
      normalized_km = product[:km].gsub(".","").to_i
      normalized_price = product[:price].gsub(".","").to_i
      normalized_year = product[:year].to_i
      url = product[:link] 
      # Benzer araçları bul
      existing_scrape = CarScrape.find_by(
        "product_url = ?",
        url
      )
      
    end
    
    # Eğer araç bulunduysa ve aynı sprint'te değilse, yeni sprint'e kopyala
    if existing_scrape && existing_scrape.sprint_id != @sprint.id
      @scrap = @sprint.car_scrapes.new(existing_scrape.attributes.except('id', 'created_at', 'updated_at', 'sprint_id'))
      @scrap.is_new = false
    else
      @scrap = existing_scrape || @sprint.car_scrapes.new
      # İlk tarama değilse ve yeni bir kayıtsa is_new true olsun
      if !@sprint.car_tracking.sprints.one? 
        @scrap.is_new = false
      elsif @sprint.car_tracking.sprints.one? and !existing_scrape
        @scrap.is_new = true
      elsif !@sprint.car_tracking.sprints.one? and existing_scrape
        @scrap.is_new = false
      end
    end
    
    @scrap.assign_attributes(
      title: product[:description],
      price: product[:price].gsub(".","").to_i,
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
