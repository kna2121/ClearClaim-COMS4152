require "rails_helper"

RSpec.describe DenialReason, type: :model do
  describe "validations" do
    it "requires code" do
      record = described_class.new
      expect(record.valid?).to be false
      expect(record.errors[:code]).to be_present
    end

    it "enforces uniqueness of code" do
      described_class.create!(code: "125")
      dup = described_class.new(code: "125")
      expect(dup.valid?).to be false
      expect(dup.errors[:code]).to be_present
    end
  end

  describe "normalization and #to_rule_hash" do
    it "normalizes codes and exports expected hash" do
      record = described_class.create!(
        code: " 125 ",
        group_code: "co",
        remark_code: " n211 ",
        rejection_code: " r12 ",
        reason_codes: [" 29 ", "29", nil],
        description: "Desc",
        suggested_correction: "Fix",
        documentation: ["doc1"]
      )

      expect(record.code).to eq("125")
      expect(record.group_code).to eq("CO")
      expect(record.remark_code).to eq("N211")
      expect(record.rejection_code).to eq("R12")
      expect(record.reason_codes).to eq(["29"]) # unique

      hash = record.to_rule_hash
      expect(hash["code"]).to eq("125")
      expect(hash["group_code"]).to eq("CO")
      expect(hash["remark_code"]).to eq("N211")
      expect(hash["reason_codes"]).to eq(["29"])
      expect(hash["description"]).to eq("Desc")
      expect(hash["reason"]).to be_present
    end

    it "provides default reason when description is blank" do
      record = described_class.create!(code: "200")
      expect(record.reason_text).to eq("Reason details unavailable.")
    end
  end
end

