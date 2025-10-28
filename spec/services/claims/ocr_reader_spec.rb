require "rails_helper"

RSpec.describe Claims::OcrReader do
  describe "#call" do
    it "parses demographics and line items from OCR text" do
      # Stub RTesseract to avoid external dependency
      fake_ocr = instance_double(RTesseract)
      ocr_text = <<~TXT
        ABC INSURANCE COMPANY
        Patient: DOE, DAVE    DOB: 01/29/1964
        Insured: DOE, DAVE    Member ID: ABC123EFG
        ICN: 202303EF123
        11/27/2024 | 99215 | $940.00 | CO29 | N211
      TXT
      allow(RTesseract).to receive(:new).and_return(fake_ocr)
      allow(fake_ocr).to receive(:to_s).and_return(ocr_text)

      result = described_class.new(file: StringIO.new("raw image")).call
      expect(result[:source]).to eq("ocr")
      expect(result[:demographics][:patient_name]).to be_present
      expect(result[:line_items]).to be_an(Array)
      expect(result[:denial_codes]).to include("CO29", "N211")
    end

    it "wraps underlying errors with a user-friendly message" do
      allow(RTesseract).to receive(:new).and_raise(StandardError.new("boom"))
      expect {
        described_class.new(file: StringIO.new("raw image")).call
      }.to raise_error(StandardError, /OCR failed: boom/)
    end
  end
end

