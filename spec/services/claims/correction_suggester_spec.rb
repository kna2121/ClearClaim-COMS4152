require "rails_helper"

RSpec.describe Claims::CorrectionSuggester do
  describe "#call" do
    let!(:co_29) do
      create(
        :denial_reason,
        code: "125",
        group_code: "CO",
        reason_codes: ["29"],
        remark_code: nil,
        description: "Denied. Bill was received after 90 days."
      )
    end

    let!(:pr_96) do
      create(
        :denial_reason,
        code: "157",
        group_code: "PR",
        reason_codes: ["96"],
        remark_code: nil,
        description: "Not responsible for replacement of contacts."
      )
    end

    it "returns database-backed suggestions when remit/remark tuples are supplied" do
      suggestions = described_class.new(
        denial_codes: [
          ["CO29", "N211"],
          ["PR96", nil]
        ]
      ).call

      expect(suggestions.size).to eq(2)

      co_response = suggestions.first
      expect(co_response[:code]).to eq("125")
      expect(co_response[:group_code]).to eq("CO")
      expect(co_response[:reason_code]).to eq("29")
      expect(co_response[:reason]).to eq("Denied. Bill was received after 90 days.")

      pr_response = suggestions.second
      expect(pr_response[:code]).to eq("157")
      expect(pr_response[:group_code]).to eq("PR")
      expect(pr_response[:reason_code]).to eq("96")
    end

    it "returns fallback when no data matches" do
      suggestions = described_class.new(denial_codes: [["CO99", "N999"]]).call

      expect(suggestions).to contain_exactly(
        a_hash_including(
          code: nil,
          group_code: "CO",
          reason_code: "99",
          remark_code: "N999",
          reason: "No rule found. Escalate to manual review."
        )
      )
    end
  end
end
