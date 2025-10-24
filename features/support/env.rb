# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'cucumber/rails'
require 'capybara/cucumber'
require 'factory_bot'
require 'rspec/expectations'

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
