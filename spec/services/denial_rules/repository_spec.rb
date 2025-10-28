require "rails_helper"

RSpec.describe DenialRules::Repository do
  describe "#fetch_by_context" do
    subject(:repository) { described_class.new }

    let!(:denial) do
      create(
        :denial_reason,
        code: "125",
        group_code: "CO",
        reason_codes: ["29"],
        remark_code: "N211",
        description: "CO group denial with remark"
      )
    end

    it "returns a rule when matching by EOB code" do
      rule = repository.fetch_by_context(code: "125")

      expect(rule).to include(
        "code" => "125",
        "group_code" => "CO",
        "remark_code" => "N211"
      )
    end

    it "returns a rule when matching by group and remark code" do
      rule = repository.fetch_by_context(group_code: "CO", remark_code: "N211")

      expect(rule).to include("code" => "125")
    end

    it "returns a rule when matching by group and reason code" do
      rule = repository.fetch_by_context(group_code: "CO", reason_code: "29")

      expect(rule).to include("code" => "125")
    end
  end
end
