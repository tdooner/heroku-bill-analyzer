require 'dotenv'
require 'selenium-webdriver'
require 'optparse'
$stdout.sync = true

def log_in(username, password, driver)
  driver.get('https://id.heroku.com/login')

  driver.find_element(name: :email).send_keys(username)
  driver.find_element(name: :password).send_keys(password)
  driver.find_element(name: :commit).click
end

def wait_for_dashboard(driver)
  sleep 10
end

def each_invoice_app(driver)
  driver.find_elements(class: 'invoice-row').first(1).each do |invoice_row|
    billing_window = driver.window_handles.first
    billing_month_label = invoice_row.find_element(class: 'bn')
    billing_month = billing_month_label.attribute('value')
    billing_month_label.click
    sleep 2
    new_window = (driver.window_handles - [billing_window]).first
    driver.switch_to.window(new_window)

    driver.find_elements(class: 'app').each do |app|
      app.find_element(class: 'app-title').click
      app_name = app.find_element(css: '.app-title .title').text
      subtotal = app.find_element(css: 'tfoot > tr > td > strong').text
      yield [billing_month, app_name, subtotal]
    end

    driver.close

    driver.switch_to.window(billing_window)
  end
end

def dump_team_bills(team, driver)
  driver.get("https://dashboard.heroku.com/teams/#{team}/billing")
  sleep 2

  each_invoice_app(driver) do |month, app, subtotal|
    puts [team, month, app, subtotal].join("\t")
  end
end

def dump_personal_bills(driver)
  driver.get('https://dashboard.heroku.com/account/billing')
  sleep 2

  each_invoice_app(driver) do |month, app, subtotal|
    puts ['Personal', month, app, subtotal].join("\t")
  end
end

def scrape(options)
  Dotenv.load

  args = []
  args.push('headless') if options[:headless]
  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: args)

  driver = Selenium::WebDriver.for(:chrome, options: chrome_options)

  $stderr.puts "Logging in as #{ENV['HEROKU_USERNAME']}..."
  log_in(ENV['HEROKU_USERNAME'], ENV['HEROKU_PASSWORD'], driver)

  $stderr.puts '  waiting for dashboard to load'
  wait_for_dashboard(driver)

  puts "Account\tMonth\tApp Name\tSubtotal"

  options[:teams].each do |team|
    $stderr.puts "  Dumping Team Bills: #{team}"
    dump_team_bills(team, driver)
  end

  $stderr.puts '  Dumping Personal Bills'
  dump_personal_bills(driver)

  driver.quit
end

options = {
  headless: true,
  teams: [],
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on('--[no-]headless', 'Run headlessly (default: true)') do |headless|
    options[:headless] = headless
  end
  opts.on('-t [team]', 'Scrape team by name (can be provided multiple times)') do |team|
    options[:teams] << team
  end
end.parse!

scrape(options)
