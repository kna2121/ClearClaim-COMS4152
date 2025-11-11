# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  class RetryProbeJob < ApplicationJob
    def perform
      raise StandardError, "boom"
    end
  end

  class DiscardProbeJob < ApplicationJob
    def perform
      raise ActiveJob::DeserializationError, "missing record"
    end
  end

  it "retries StandardError with the configured backoff" do
    job = RetryProbeJob.new
    allow(job).to receive(:retry_job).and_call_original

    job.perform_now rescue nil

    expect(job).to have_received(:retry_job).with(hash_including(wait: be_within(0.6).of(5.seconds)))
  end

  it "discards ActiveJob::DeserializationError without bubbling" do
    expect { DiscardProbeJob.perform_now }.not_to raise_error
  end
end
