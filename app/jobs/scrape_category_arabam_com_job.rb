class ScrapeCategoryArabamComJob < ApplicationJob
  queue_as :default

  def perform(*args)
    require 'open-uri'
    require 'nokogiri'
    require 'webrick/httputils'
    require 'net/http'
    require 'uri'

    Rails.logger.info "Starting ScrapeCategoryArabamComJob"

    @company = Company.find 2
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

    products = []
    link = "https://www.arabam.com/ikinci-el"
    doc = URI.open(link, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
    page_html.css(".category-facet")[0].css("ul")[0].css("li").each do |item|
      category_name = item.css("a").text.strip.split("\r").first
      category_url = "https://www.arabam.com" + URI.encode_www_form_component(item.css("a").first["href"])
      category = Category.find_or_create_by(name: category_name, category_url: category_url, company_id: @company.id)
      category.save
      Rails.logger.info "Created/Found category: #{category.id}"

      #category is brand
      doc = URI.open(category_url, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      category_page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
      if category_page_html.css(".category-facet").css("ul").last.css("li").count > 0
        category_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
          brand_name = item.css("a").text.strip.split("\r").first
          brand_url = "https://www.arabam.com" + URI.encode_www_form_component(item.css("a").first["href"])
          brand = Brand.find_or_create_by(name: brand_name, brand_url: brand_url, category_id: category.id)
          brand.save
          Rails.logger.info "Created/Found brand: #{brand.id}"

          #brand is model
          doc = URI.open(brand_url, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          model_page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
          if model_page_html.css(".category-facet").css("ul").last.css("li").count > 0
            model_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
              model_name = item.css("a").text.strip.split("\r").first
              model_url = "https://www.arabam.com" + URI.encode_www_form_component(item.css("a").first["href"])
              model = Model.find_or_create_by(name: model_name, model_url: model_url, brand_id: brand.id)
              model.save
              Rails.logger.info "Created/Found model: #{model.id}"

              #model is series
              doc = URI.open(model_url, 'User-Agent' => agent, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
              serials_page_html = Nokogiri::HTML(doc.read, nil, "UTF-8")
              if serials_page_html.css(".category-facet").css("ul").last.css("li").count > 0
                serials_page_html.css(".category-facet").css("ul").last.css("li").each do |item|
                  serial_name = item.css("a").text.strip.split("\r").first
                  serial_url = "https://www.arabam.com" + URI.encode_www_form_component(item.css("a").first["href"])
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
    Rails.logger.info "Found #{products.count} categories"
  end
end
