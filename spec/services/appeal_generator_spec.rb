require "rails_helper"

RSpec.describe Appeals::AppealGenerator do
  describe "#call" do
    it "renders the default template and returns text" do
      claim = { patient_name: "DOE, DAVE", claim_number: "202303EF123", service_period: "11/27/2024" }
      reasons = [{ code: "125", group_code: "CO", reason_code: "29", reason: "Late filing" }]

      result = described_class.new(claim: claim, denial_reasons: reasons).call
      expect(result[:format]).to eq(:text)
      expect(result[:body]).to be_a(String)
      expect(result[:metadata][:template]).to eq("default_letter")
    end

    it "raises when template does not exist" do
      claim = { patient_name: "DOE, DAVE" }
      expect {
        described_class.new(claim: claim, denial_reasons: [], template: "missing_template").call
      }.to raise_error(ArgumentError, /template missing_template not found/)
    end
  end
end

