# frozen_string_literal: true

begin
  require 'database_cleaner/active_record'
rescue LoadError => e
  warn "Add database_cleaner-active_record to your Gemfile: #{e.message}"
end

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end
