# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'cucumber/rails'
require 'capybara/cucumber'
require 'selenium-webdriver'
require 'factory_bot'
require 'rspec/expectations'
require 'rspec/mocks'
require_relative 'simplecov'

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.clean_with(:truncation)
rescue NameError
  raise "You need to add 'database_cleaner-active_record' to your Gemfile."
end

Cucumber::Rails::Database.javascript_strategy = :truncation

World(FactoryBot::Syntax::Methods)
World(RSpec::Matchers)
World(RSpec::Mocks::ExampleMethods)

Before do
  RSpec::Mocks.setup
end

After do
  RSpec::Mocks.verify
  RSpec::Mocks.teardown
end


# Pick a JS driver that is likely available without external downloads
preferred = if Capybara.drivers.key?(:selenium_chrome_headless)
  :selenium_chrome_headless
elsif Capybara.drivers.key?(:selenium_headless)
  :selenium_headless
elsif Capybara.drivers.key?(:selenium_chrome)
  :selenium_chrome
elsif Capybara.drivers.key?(:selenium)
  :selenium
else
  :rack_test
end
Capybara.javascript_driver = preferred
Capybara.default_max_wait_time = 10

# If a JS-capable driver isn't usable (e.g., no local driver and network blocked),
# gracefully skip @javascript scenarios instead of failing.
Before('@javascript') do
  begin
    session = Capybara::Session.new(Capybara.javascript_driver, Capybara.app)
    session.visit('about:blank')
    session.driver.quit if session.driver.respond_to?(:quit)
  rescue StandardError => e
    warn "Skipping @javascript scenario due to driver error: #{e.class}: #{e.message}"
    if respond_to?(:skip_this_scenario)
      skip_this_scenario("JS driver unavailable: #{e.message}")
    else
      pending("JS driver unavailable: #{e.message}")
    end
  end
end
