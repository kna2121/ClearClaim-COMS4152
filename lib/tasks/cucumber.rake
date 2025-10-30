unless ENV["RAILS_ENV"] == "production"
  begin
    require "cucumber/rake/task"
    Cucumber::Rake::Task.new(:features)
  rescue LoadError
    puts "Cucumber not available"
  end
end
