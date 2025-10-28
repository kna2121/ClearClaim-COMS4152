require "rails_helper"

# RSpec tests for Claims::PdfAnalyzer
#
# These tests ensure the PDF parser correctly extracts:
# 1. Demographic information (patient, DOB, member ID, etc.)
# 2. Billing line items with remit/remark codes
# 3. Handles edge cases (missing data, malformed PDFs)
#
# Ruby/RSpec Concepts Explained:
# - `describe`: Groups related tests (like a test suite)
# - `let`: Lazy-loaded test data (created only when referenced)
# - `let!`: Eager-loaded (created before each test)
# - `subject`: The object being tested
# - `expect(...).to`: Assertion syntax
# - `be_present`, `include`, `eq`: RSpec matchers
#
RSpec.describe Claims::PdfAnalyzer do
  # The main method we're testing: analyzer.call
  describe "#call" do
    # `subject` is the object under test
    # This creates a new PdfAnalyzer with our test file
    subject(:analyzer) { described_class.new(file: test_file) }

    # `let` creates a variable that's available in all tests
    # `let` is lazy - it's only created when first referenced
    let(:test_file) { File.open(pdf_path) }
    let(:pdf_path) { Rails.root.join("spec", "fixtures", "files", "sample_eob.pdf") }

    # Context: Group tests for similar scenarios
    # This groups all tests for valid PDF files
    context "when analyzing a valid EOB PDF" do
      # Before block: Runs before each test
      # Creates a temporary test PDF file
      before do
        create_test_pdf
      end

      # After block: Cleanup after each test
      after do
        test_file.close if test_file && !test_file.closed?
        FileUtils.rm_f(pdf_path) if File.exist?(pdf_path)
      end

      # Individual test case
      # `it` describes what the test verifies
      it "extracts the source as 'pdf'" do
        result = analyzer.call
        expect(result[:source]).to eq("pdf")
      end

      it "extracts raw text from the PDF" do
        result = analyzer.call
        expect(result[:raw_text]).to be_present
        expect(result[:raw_text]).to include("REMITTANCE ADVICE")
      end

      # Nested describe: Tests for demographic extraction
      describe "demographic extraction" do
        let(:demographics) { analyzer.call[:demographics] }

        it "extracts patient name" do
          expect(demographics[:patient_name]).to eq("DOE, DAVE")
        end

        it "extracts date of birth" do
          expect(demographics[:dob]).to eq("01/29/1964")
        end

        it "extracts insured name" do
          expect(demographics[:insured]).to eq("DOE, DAVE")
        end

        it "extracts member ID" do
          expect(demographics[:member_id]).to eq("ABC123EFG")
        end

        it "extracts ICN (Internal Control Number)" do
          expect(demographics[:icn]).to eq("202303EF123")
        end
      end

      # Tests for line item extraction
      describe "line item extraction" do
        let(:line_items) { analyzer.call[:line_items] }

        it "extracts multiple line items" do
          expect(line_items).to be_an(Array)
          expect(line_items.size).to be >= 1
        end

        # Test the first line item in detail
        describe "first line item" do
          let(:first_item) { line_items.first }

          it "extracts service date" do
            expect(first_item[:service_date]).to eq("11/27/2024")
          end

          it "extracts procedure code" do
            expect(first_item[:procedure_code]).to match(/^\d{5}[A-Z]?$/)
          end

          it "extracts billed amount" do
            expect(first_item[:billed]).to be_a(Numeric)
            expect(first_item[:billed]).to be >= 0
          end

          it "extracts allowed amount" do
            expect(first_item[:allowed]).to be_a(Numeric)
          end

          it "extracts remit codes as array" do
            expect(first_item[:remit_codes]).to be_an(Array)
          end

          it "extracts remark codes as array" do
            expect(first_item[:remark_codes]).to be_an(Array)
          end

          it "extracts paid amount" do
            expect(first_item[:paid]).to be_a(Numeric)
          end
        end

        # Verify specific codes from our test PDF
        it "identifies CO29 remit code" do
          co29_items = line_items.select { |item| item[:remit_codes].include?("CO29") }
          expect(co29_items).not_to be_empty
        end

        it "identifies N211 remark code" do
          n211_items = line_items.select { |item| item[:remark_codes].include?("N211") }
          expect(n211_items).not_to be_empty
        end
      end

      # Test denial codes extraction (legacy format)
      describe "denial codes extraction" do
        let(:denial_codes) { analyzer.call[:denial_codes] }

        it "returns an array of codes" do
          expect(denial_codes).to be_an(Array)
        end

        it "includes remit codes" do
          expect(denial_codes).to include(match(/^(CO|PR|OA|CR|PI)\d+$/))
        end

        it "includes remark codes" do
          expect(denial_codes).to include(match(/^[NM]\d{2,4}$/))
        end

        it "returns unique codes only" do
          expect(denial_codes).to eq(denial_codes.uniq)
        end
      end

      # Test backward compatibility fields
      describe "backward compatibility" do
        let(:result) { analyzer.call }

        it "provides patient_name at root level" do
          expect(result[:patient_name]).to eq(result[:demographics][:patient_name])
        end

        it "provides claim_number (ICN) at root level" do
          expect(result[:claim_number]).to eq(result[:demographics][:icn])
        end

        it "provides service_period" do
          expect(result[:service_period]).to be_present
        end
      end
    end

    # Edge case: Malformed PDF
    context "when PDF is malformed" do
      let(:test_file) { StringIO.new("not a valid pdf") }

      it "raises StandardError with helpful message" do
        expect { analyzer.call }.to raise_error(StandardError, /Unable to read PDF/)
      end
    end

    # Edge case: Empty PDF
    context "when PDF has no recognizable data" do
      before do
        create_empty_pdf
      end

      after do
        test_file.close if test_file && !test_file.closed?
        FileUtils.rm_f(pdf_path) if File.exist?(pdf_path)
      end

      it "returns empty demographics" do
        result = analyzer.call
        demographics = result[:demographics]
        
        expect(demographics[:patient_name]).to be_nil
        expect(demographics[:dob]).to be_nil
        expect(demographics[:member_id]).to be_nil
      end

      it "returns empty line items array" do
        result = analyzer.call
        expect(result[:line_items]).to be_empty
      end
    end

    # Edge case: PDF with missing fields
    context "when PDF has partial data" do
      before do
        create_partial_pdf
      end

      after do
        test_file.close if test_file && !test_file.closed?
        FileUtils.rm_f(pdf_path) if File.exist?(pdf_path)
      end

      it "extracts available fields and returns nil for missing ones" do
        result = analyzer.call
        demographics = result[:demographics]
        
        # Should have patient name but not DOB
        expect(demographics[:patient_name]).to be_present
        expect(demographics[:dob]).to be_nil
      end
    end
  end

  # Test private methods through their public interface
  describe "code extraction methods" do
    subject(:analyzer) { described_class.new(file: StringIO.new("")) }

    describe "remit code patterns" do
      it "matches CO codes" do
        text = "Line has CO29 denial"
        codes = analyzer.send(:extract_remit_codes, text)
        expect(codes).to include("CO29")
      end

      it "matches PR codes" do
        text = "Line has PR3 denial"
        codes = analyzer.send(:extract_remit_codes, text)
        expect(codes).to include("PR3")
      end

      it "matches multiple codes" do
        text = "CO29 and PR3 and OA45"
        codes = analyzer.send(:extract_remit_codes, text)
        expect(codes).to include("CO29", "PR3", "OA45")
      end
    end

    describe "remark code patterns" do
      it "matches N codes" do
        text = "Remark N211"
        codes = analyzer.send(:extract_remark_codes, text)
        expect(codes).to include("N211")
      end

      it "matches M codes" do
        text = "Remark M86"
        codes = analyzer.send(:extract_remark_codes, text)
        expect(codes).to include("M86")
      end
    end
  end

  # Helper methods to create test PDFs
  # In real implementation, these would create actual PDF files
  # For now, they create simple text-based "PDFs" for testing

  def create_test_pdf
    FileUtils.mkdir_p(File.dirname(pdf_path))
    
    # Create a simple PDF-like structure with test data
    # In production, you'd use a real PDF library (prawn, combine_pdf)
    content = <<~EOB
      ABC INSURANCE COMPANY
      REMITTANCE ADVICE
      
      Patient: DOE, DAVE    DOB: 01/29/1964
      Insured: DOE, DAVE    Member ID: ABC123EFG
      ICN: 202303EF123
      
      Service Date   POS NOS Procedure  Billed    Allowed   Remit    Remark   Paid
      11/27/2024     11  1   99215      940.00    0.00      CO29     N211     0.00
      11/27/2024     11  1   G2211      50.00     0.00      CO29     N211     0.00
      11/27/2024     11  1   80307      250.00    0.00      PR3      N211     0.00
    EOB
    
    # Use prawn to create a real PDF
    require 'prawn'
    Prawn::Document.generate(pdf_path) do
      text content
    end
  end

  def create_empty_pdf
    FileUtils.mkdir_p(File.dirname(pdf_path))
    require 'prawn'
    Prawn::Document.generate(pdf_path) do
      text "Empty document"
    end
  end

  def create_partial_pdf
    FileUtils.mkdir_p(File.dirname(pdf_path))
    require 'prawn'
    Prawn::Document.generate(pdf_path) do
      text "Patient: SMITH, JOHN\nSome other text without DOB"
    end
  end
end