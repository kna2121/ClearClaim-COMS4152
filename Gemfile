source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.5"

gem "rails", "~> 7.1.3"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "sass-rails", "~> 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", "~> 5.0"
gem "bootsnap", require: false
gem "rack-cors"
gem "pdf-reader"
gem "combine_pdf"
gem "rtesseract"
gem "caracal"
gem "prawn"
gem "sidekiq"
gem "attr_encrypted"

group :development, :test do
  gem "sqlite3", "~> 1.4"
  gem "byebug"
  gem "rspec-rails", "~> 6.1"
  gem "cucumber-rails", require: false
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
  gem "listen", "~> 3.8"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "simplecov", require: false
end
