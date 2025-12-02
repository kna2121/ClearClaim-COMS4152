

token = ENV["OPENAI_API_KEY"] || (Rails.env.test? ? "test" : nil)
raise KeyError, "OPENAI_API_KEY missing" if token.blank?

OpenAI.configure do |config|
  config.access_token = token
  config.request_timeout = 240
end
