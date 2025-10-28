require "rtesseract"

module Claims
  # OCR-based extraction for scanned EOB documents
  # 
  # This class handles image-based PDFs and scanned documents
  # that cannot be read by the standard PDF text extraction.
  # 
  # Uses Tesseract OCR to convert images to text, then applies
  # the same parsing logic as PdfAnalyzer.
  #
  # Note: Requires tesseract to be installed on the system:
  #   macOS: brew install tesseract
  #   Ubuntu: apt-get install tesseract-ocr
  #
  class OcrReader
    # Reuse the same regex patterns as PdfAnalyzer for consistency
    REMIT_CODE_REGEX = /\b(CO|PR|OA|CR|PI)\s*(\d{1,4})\b/
    REMARK_CODE_REGEX = /\b([NM]\d{2,4})\b/

    def initialize(file:)
      @file = file
    end

    # Main extraction method - mirrors PdfAnalyzer.call
    # @return [Hash] with same structure as PdfAnalyzer
    def call
      text = extract_text
      
      demographics = extract_demographics(text)
      line_items = extract_line_items(text)
      all_denial_codes = extract_all_denial_codes(text)
      
      {
        source: "ocr",
        raw_text: text,
        demographics: demographics,
        line_items: line_items,
        denial_codes: all_denial_codes,
        # Legacy compatibility
        patient_name: demographics[:patient_name],
        claim_number: demographics[:icn],
        service_period: extract_service_period(line_items)
      }
    end

    private

    attr_reader :file

    # Extracts text using Tesseract OCR
    # @return [String] recognized text
    def extract_text
      path = resolve_path
      
      # RTesseract.new creates a Tesseract instance
      # .to_s runs OCR and returns the recognized text
      RTesseract.new(path).to_s
    rescue => e
      raise StandardError, "OCR failed: #{e.message}"
    ensure
      # Clean up temp file if we created one
      temp_file&.close!
    end

    # Resolves file path (handles both File objects and uploaded files)
    def resolve_path
      return file.path if file.respond_to?(:path)
      temp_file.path
    end

    # Creates temporary file for uploaded content
    def temp_file
      return @temp_file if defined?(@temp_file)

      buffer = Tempfile.new(["claim-ocr", ".png"])
      payload = file.respond_to?(:read) ? file.read : file.to_s
      buffer.binmode
      buffer.write(payload)
      buffer.rewind
      @temp_file = buffer
    end

    # Extract demographics - same logic as PdfAnalyzer
    # OCR may have slight variations in spacing/formatting
    def extract_demographics(text)
      {
        patient_name: extract_label_value(text, "Patient"),
        dob: match_value(text, /DOB:\s*([\d\/\-]+)/),
        insured: extract_label_value(text, "Insured"),
        member_id: match_value(text, /Member\s+ID:\s*(\S+)/i),
        icn: match_value(text, /ICN:\s*(\S+)/i)
      }
    end

    # Extract line items - same logic as PdfAnalyzer
    # OCR text may have more noise/errors, so we're more lenient
    def extract_line_items(text)
      line_items = []
      
      text.each_line do |line|
        # Skip lines without dates
        next unless line.match?(/\d{1,2}\/\d{1,2}\/\d{4}/)
        
        # Skip lines without procedure codes
        # Support CPT (five digits, optional trailing letter) and HCPCS (letter + 4 digits)
        next unless line.match?(/\b(?:\d{5}[A-Z]?|[A-Z]\d{4})\b/)
        
        service_date = match_value(line, /(\d{1,2}\/\d{1,2}\/\d{4})/)
        procedure_code = match_value(line, /\b(\d{5}[A-Z]?|[A-Z]\d{4})\b/)
        
        # Extract dollar amounts
        amounts = line.scan(/\d+\.\d{2}/).map(&:to_f)
        
        remit_codes = extract_remit_codes(line)
        remark_codes = extract_remark_codes(line)
        
        if service_date && procedure_code
          line_items << {
            service_date: service_date,
            procedure_code: procedure_code,
            billed: amounts[0] || 0.0,
            allowed: amounts[1] || 0.0,
            remit_codes: remit_codes,
            remark_codes: remark_codes,
            paid: amounts.last || 0.0
          }
        end
      end
      
      line_items
    end

    # Extract remit codes
    def extract_remit_codes(text)
      codes = []
      text.scan(REMIT_CODE_REGEX) do |match|
        codes << "#{match[0]}#{match[1]}"
      end
      codes.uniq
    end

    # Extract remark codes
    def extract_remark_codes(text)
      text.scan(REMARK_CODE_REGEX).flatten.uniq
    end

    # Get all denial codes (remit + remark)
    def extract_all_denial_codes(text)
      remit = extract_remit_codes(text)
      remark = extract_remark_codes(text)
      (remit + remark).uniq
    end

    # Extract service period from line items
    def extract_service_period(line_items)
      return nil if line_items.empty?
      
      dates = line_items.map { |item| item[:service_date] }.compact
      return dates.first if dates.size == 1
      
      "#{dates.first} - #{dates.last}"
    end

    # Utility: Extract single value with regex
    def match_value(text, regex)
      match = text.match(regex)
      match ? match[1].strip : nil
    end

    # Extract a labeled value on a single line, trimming at the next label.
    def extract_label_value(text, label)
      line = text.each_line.find { |l| l.match?(/\b#{Regexp.escape(label)}:/i) }
      return nil unless line
      value = line.split(/#{Regexp.escape(label)}:\s*/i, 2)[1].to_s
      value = value.split(/\s{2,}[A-Z][A-Za-z\s\/#-]*:/, 2)[0].to_s
      value.strip.presence
    end
  end
end
