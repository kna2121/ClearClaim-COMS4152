require "rails_helper"

RSpec.describe Claims::PdfAnalyzer do
  describe "enhanced field extraction" do
    let(:pdf_path) { Rails.root.join("spec", "fixtures", "files", "complete_eob.pdf") }
    let(:analyzer) { described_class.new(file: File.open(pdf_path)) }

    before do
      FileUtils.mkdir_p(File.dirname(pdf_path))
      require 'prawn'
      Prawn::Document.generate(pdf_path) do
        text "ABC INSURANCE COMPANY"
        text "123 INSURANCE LANE"
        text "REMITTANCE ADVICE"
        move_down 10
        text "Patient: DOE, DAVE    DOB: 01/29/1964"
        text "Insured: DOE, DAVE    Member ID: ABC123EFG"
        text "ICN: 202303EF123"
        text "ClearClaim Assistant"
        move_down 10
        text "Service Details:"
        text "11/27/2024 | 11 | 1 | 99215 | 940.00 | 0.00 | CO29 | N211 | 0.00"
        text "11/27/2024 | 11 | 1 | G2211 | 50.00 | 0.00 | CO29 | N211 | 0.00"
      end
    end

    after do
      File.close(File.open(pdf_path)) rescue nil
      FileUtils.rm_f(pdf_path)
    end

    it "extracts payer name" do
      result = analyzer.call
      expect(result[:payer_name]).to eq("ABC INSURANCE COMPANY")
    end

    it "extracts submitter/provider name" do
      result = analyzer.call
      expect(result[:submitter_name]).to include("ClearClaim Assistant")
    end

    it "extracts claim number as ICN" do
      result = analyzer.call
      expect(result[:claim_number]).to eq("202303EF123")
    end

    it "calculates service period correctly for same-day services" do
      result = analyzer.call
      expect(result[:service_period]).to eq("11/27/2024")
    end

    it "returns data structure compatible with suggest_corrections API" do
      result = analyzer.call
      # Should have line items with remit and remark codes
      expect(result[:line_items].first).to include(
        :remit_codes,
        :remark_codes
      )
    end

    it "returns data structure compatible with generate_appeal API" do
      result = analyzer.call
      # Should have all required fields
      expect(result).to include(
        :claim_number,
        :patient_name,
        :payer_name,
        :service_period,
        :submitter_name
      )
    end
  end
end