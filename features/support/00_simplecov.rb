# features/support/simplecov.rb
require 'simplecov'
SimpleCov.command_name 'Cucumber'     
SimpleCov.coverage_dir 'coverage/cucumber'

SimpleCov.start 'rails' do
  add_filter '/features/'  # ignore cucumber test files themselves
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
end

puts "✅ SimpleCov started for Cucumber..."
