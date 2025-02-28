require 'selenium-webdriver'
require 'csv'
require 'uri'
require 'cgi'

class AmazonCrawler
  def initialize
    options = Selenium::WebDriver::Chrome::Options.new
    
    # Podstawowe opcje stealth mode
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--start-maximized')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--no-sandbox')
    
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    options.add_argument("--user-agent=#{user_agent}")
    
    @driver = Selenium::WebDriver.for :chrome, options: options
    @base_url = 'https://www.amazon.pl'
    @products = []
    @delays = -> { sleep(2 + rand(3)) }
  end

  def search_products(keyword)
    begin
      url = "#{@base_url}/s?k=#{CGI.escape(keyword)}"
      puts "Wyszukiwanie: #{keyword}"
      @driver.get(url)
      @delays.call
      
      simulate_natural_browsing
      
      puts "Oczekiwanie na załadowanie produktów..."
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      
      products = wait.until { 
        @driver.find_elements(css: 'div.s-result-item[data-component-type="s-search-result"]')
      }
      
      puts "Znaleziono #{products.length} produktów"
      
      # Zapis źródła strony przed ekstrakcją danych
      File.write('page_source.html', @driver.page_source)
      puts "Zapisano źródło strony do page_source.html dla analizy"
      
      products.each_with_index do |product, index|
        puts "\nPrzetwarzanie produktu #{index + 1}:"
        extract_and_save_product(product)
        @delays.call
      end
      
    rescue => e
      puts "Błąd podczas wyszukiwania: #{e.message}"
    end
  end

  def save_to_csv(filename)
    CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      csv << ['Tytuł', 'Cena', 'URL', 'ASIN']
      @products.each do |product|
        csv << [product[:title], product[:price], product[:url], product[:asin]]
      end
    end
    puts "Zapisano produkty do #{filename}"
  end

  def quit
    @driver&.quit rescue nil
  end

  private

  def simulate_natural_browsing
    3.times do
      scroll_amount = rand(300..700)
      @driver.execute_script("window.scrollBy(0, #{scroll_amount})")
      sleep(1 + rand(2))
    end
  end

  def extract_and_save_product(product)
    begin
      title_selectors = [
        'h2.a-size-base-plus span',
        'h2 a.a-link-normal span',
        'h2[aria-label]'
      ]
      
      price_selectors = [
        'span.a-price-whole',
        'span.a-offscreen',
        '.a-price .a-offscreen'
      ]
      
      url_selectors = [
        '.s-product-image-container a.a-link-normal',
        '.rush-component a.a-link-normal',
        '.s-title-instructions-style a.a-link-normal'
      ]

      title = find_element_with_selectors(product, title_selectors)
      price = find_nested_element(product, price_selectors)
      url = find_nested_element(product, url_selectors, 'href')
      asin = product.attribute('data-asin')

      if title && price && url && asin
        clean_url = url.split('/ref=')[0].strip
        data = {
          title: title.strip,
          price: price.gsub(/[^\d,]/, ''),
          url: clean_url.start_with?('http') ? clean_url : "https://www.amazon.pl#{clean_url}",
          asin: asin
        }
        @products << data
        puts "Dodano produkt: #{data[:title]} (#{data[:price]})"
      else
        puts "Nie udało się znaleźć wszystkich danych:"
        puts "Tytuł: #{title || 'brak'}"
        puts "Cena: #{price || 'brak'}" 
        puts "URL: #{url || 'brak'}"
        puts "ASIN: #{asin || 'brak'}"
      end
    rescue => e
      puts "Błąd podczas przetwarzania produktu: #{e.message}"
    end
  end

  def find_element_with_selectors(product, selectors, attribute = nil)
    selectors.each do |selector|
      begin
        element = product.find_element(css: selector)
        return attribute ? element.attribute(attribute) : element.text.strip
      rescue
        next
      end
    end
    nil
  end

  def find_nested_element(product, selectors, attribute = nil)
    selectors.each do |selector|
      begin
        elements = product.find_elements(css: selector)
        elements.each do |element|
          value = attribute ? element.attribute(attribute) : element.text
          return value if value && !value.empty?
        end
      rescue
        next
      end
    end
    nil
  end
end

begin
  crawler = AmazonCrawler.new
  crawler.search_products('laptop')
  crawler.save_to_csv('produkty_amazon.csv')
ensure
  crawler&.quit
end