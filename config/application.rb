# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module AiAppealAssistant
  class Application < Rails::Application
    config.load_defaults 7.1
    config.generators do |g|
      g.test_framework :rspec
      g.system_tests nil
      g.helper_specs false
      g.view_specs false
    end
    config.assets.paths << Rails.root.join('app', 'assets', 'javascripts')
  end
end
