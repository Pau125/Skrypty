require 'selenium-webdriver'
require 'csv'

class AllegroCrawler
  def initialize
    options = Selenium::WebDriver::Chrome::Options.new
    
    # Podstawowe opcje stealth mode
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--start-maximized')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--no-sandbox')
    
    # Losowy User-Agent
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    options.add_argument("--user-agent=#{user_agent}")
    
    @driver = Selenium::WebDriver.for :chrome, options: options
    execute_stealth_scripts
    
    @base_url = 'https://allegro.pl'
    @products = []
    @delays = -> { sleep(3 + rand(5)) }
  end

  def crawl_category(category_url)
    begin
      puts "Otwieranie strony: #{category_url}"
      @driver.get(category_url)
      @delays.call
      
      simulate_natural_browsing
      
      if has_captcha?
        puts "Wykryto CAPTCHA. Czekam na ręczne rozwiązanie..."
        wait_for_user_input
      end
      
      puts "Oczekiwanie na załadowanie produktów..."
      wait = Selenium::WebDriver::Wait.new(timeout: 30)
      
      File.write('page_source.html', @driver.page_source)
      puts "Zapisano źródło strony do page_source.html"
      
      selectors = [
        'div[data-box-name="items-v3"] > div',
        'section[data-box-name="items-v3"] article',
        'div[data-role="offer-listing"] article'
      ]
      
      found = false
      products = nil
      
      selectors.each do |selector|
        begin
          puts "Próba selektora: #{selector}"
          wait.until { @driver.find_elements(css: selector).size > 0 }
          products = @driver.find_elements(css: selector)
          puts "Znaleziono #{products.length} produktów używając selektora: #{selector}"
          found = true
          break
        rescue => e
          puts "Selektor #{selector} nie zadziałał: #{e.message}"
        end
      end
      
      unless found
        puts "Nie udało się znaleźć produktów. Sprawdź plik page_source.html"
        return
      end
      
      products.each do |product|
        extract_and_save_product(product)
        @delays.call
      end
      
    rescue => e
      puts "Błąd podczas pobierania strony: #{e.message}"
    end
  end

  def search_products(keyword)
    search_url = "#{@base_url}/listing?string=#{URI.encode(keyword)}"
    crawl_category(search_url)
  end

  def save_to_csv(filename)
    CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      csv << ['Tytuł', 'Cena', 'URL', 'ID']
      @products.each do |product|
        csv << [product[:title], product[:price], product[:url], product[:id]]
      end
    end
  end

  def quit
    @driver&.quit rescue nil
  end

  private

  def execute_stealth_scripts
    @driver.execute_script(
      "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
    )
  end

  def simulate_natural_browsing
    # Losowe scrollowanie
    3.times do
      scroll_amount = rand(300..700)
      @driver.execute_script("window.scrollBy(0, #{scroll_amount})")
      sleep(1 + rand(2))
    end
  end

  def has_captcha?
    begin
      @driver.find_element(css: 'div[class*="captcha"]').displayed?
    rescue
      false
    end
  end

  def wait_for_user_input
    puts "Naciśnij ENTER po rozwiązaniu CAPTCHA..."
    gets
  end

  def extract_and_save_product(product)
    begin
      data = {
        title: product.find_element(css: 'h2, [data-role="title"]').text.strip,
        price: product.find_element(css: '[data-role="price"], .price').text.strip,
        url: product.find_element(tag_name: 'a').attribute('href'),
        id: product.attribute('data-item-id') || product.attribute('id')
      }
      @products << data
      puts "Dodano produkt: #{data[:title]}"
    rescue => e
      puts "Błąd podczas ekstrahowania danych: #{e.message}"
    end
  end
end

# Przykład użycia:
begin
  crawler = AllegroCrawler.new
  crawler.crawl_category('https://allegro.pl/kategoria/elektronika')
  crawler.save_to_csv('produkty_allegro.csv')
ensure
  crawler&.quit
end