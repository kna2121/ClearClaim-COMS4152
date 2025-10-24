# frozen_string_literal: true

require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:cucumber) do |task|
  task.cucumber_opts = ['--format', 'pretty']
end
