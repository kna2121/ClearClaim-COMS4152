require "rails_helper"

RSpec.describe Appeals::AppealGenerator do
  let(:claim) do
    {
      claim_number: "ZZ999",
      patient_name: "Test Patient",
      payer_name: "Test Payer",
      service_period: "01/01/2025"
    }
  end
  let(:denial_reasons) do
    [
      { code: "CO197", reason: "Missing pre-authorization", suggested_correction: "Submit pre-auth documentation" }
    ]
  end

  it "falls back to template in test env" do
    result = described_class.new(claim: claim, denial_reasons: denial_reasons).call
    expect(result[:appeal_letter]).to include("Appeals Department")
    expect(result[:appeal_letter]).to include("Test Payer")
  end

  it "uses OpenAI client when not test env and key present" do
    # Simulate non-test environment and a present API key
    allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
    old_key = ENV["OPENAI_API_KEY"]
    begin
      ENV["OPENAI_API_KEY"] = "fake-key"
      fake_client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:chat).and_return(
        {
          "choices" => [
            { "message" => { "content" => "Generated appeal content from LLM" } }
          ]
        }
      )

      result = described_class.new(claim: claim, denial_reasons: denial_reasons).call
      expect(result[:appeal_letter]).to eq("Generated appeal content from LLM")
    ensure
      ENV["OPENAI_API_KEY"] = old_key
    end
  end
end
