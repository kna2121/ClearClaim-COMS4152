

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai, :api_key)
  config.request_timeout = 240
end

# In application code you can create a client like below.
client = OpenAI::Client.new
# => #<OpenAI::Client:0x000000010ee5dcd8>