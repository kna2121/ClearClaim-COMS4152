# frozen_string_literal: true

begin
  require 'database_cleaner/active_record'
rescue LoadError => e
  warn "Add database_cleaner-active_record to your Gemfile: #{e.message}"
end

Before do |scenario|
  # Allow scenarios to opt-out of DB usage (e.g., pure unit-style tests)
  @skip_db_cleaner = scenario.respond_to?(:source_tag_names) && scenario.source_tag_names.include?('@no_db')
  DatabaseCleaner.start unless @skip_db_cleaner
end

After do |scenario|
  DatabaseCleaner.clean unless @skip_db_cleaner
end
