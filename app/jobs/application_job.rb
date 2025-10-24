# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError
end
