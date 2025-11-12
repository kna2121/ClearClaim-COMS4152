require "rails_helper"

RSpec.describe Claims::DocumentAnalyzer do
  describe "#call" do
    context "with a real PDF file" do
      let(:pdf_path) { Rails.root.join("spec", "fixtures", "files", "da_sample.pdf") }

      before do
        FileUtils.mkdir_p(File.dirname(pdf_path))
        require 'prawn'
        Prawn::Document.generate(pdf_path) do
          text "Patient: DOE, DAVE    DOB: 01/29/1964"
          text "Insured: DOE, DAVE    Member ID: ABC123EFG"
          text "ICN: 202303EF123"
          text "11/27/2024 | 99215 | $940.00 | CO29 | N211"
        end
      end

      after do
        FileUtils.rm_f(pdf_path)
      end

      it "routes to PdfAnalyzer and returns parsed data" do
        File.open(pdf_path, 'rb') do |file|
          result = described_class.new(file: file).call
          expect(result[:source]).to eq("pdf")
          expect(result[:demographics][:patient_name]).to eq("DOE, DAVE")
        end
      end
    end

    context "when IO looks like a PDF via header but has no filename" do
      it "routes to PdfAnalyzer (sniffed by %PDF-)" do
        fake_pdf_io = StringIO.new("%PDF- fake header")

        fake_analyzer = instance_double(Claims::PdfAnalyzer)
        expect(Claims::PdfAnalyzer).to receive(:new).with(file: fake_pdf_io).and_return(fake_analyzer)
        expect(fake_analyzer).to receive(:call).and_return({ source: "pdf" })

        result = described_class.new(file: fake_pdf_io).call
        expect(result[:source]).to eq("pdf")
      end
    end

    context "with a non-PDF file (e.g., PNG)" do
      it "raises an error indicating only PDFs are supported" do
        png_io = StringIO.new("\x89PNG anything")
        expect {
          described_class.new(file: png_io).call
        }.to raise_error(ArgumentError, /Only PDF files are supported/)
      end
    end

    context "with a corrupted PDF file" do
      let(:pdf_path) { Rails.root.join("spec", "fixtures", "files", "corrupted.pdf") }

      before do
        FileUtils.mkdir_p(File.dirname(pdf_path))
        File.write(pdf_path, "This is not a valid pdf")
      end

      after do
        FileUtils.rm_f(pdf_path)
      end

      it "raises a helpful error from PdfAnalyzer" do
        File.open(pdf_path, 'rb') do |file|
          expect {
            described_class.new(file: file).call
          }.to raise_error(StandardError, /Unable to read PDF/)
        end
      end
    end
  end
end
