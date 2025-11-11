# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  it "sets a default from address" do
    expect(ApplicationMailer.default[:from]).to eq("from@example.com")
  end

  it "uses the mailer layout" do
    expect(ApplicationMailer._layout.to_s).to eq("mailer")
  end
end
