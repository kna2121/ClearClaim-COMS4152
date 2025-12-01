# frozen_string_literal: true

require 'simplecov'
SimpleCov.command_name 'Rspec'     
SimpleCov.coverage_dir 'coverage/rspec'

SimpleCov.start 'rails' do
  add_filter %w[spec config]
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
