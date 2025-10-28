# frozen_string_literal: true

# Allow ampersands and other HTML entities to remain unescaped in JSON responses.
ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false
