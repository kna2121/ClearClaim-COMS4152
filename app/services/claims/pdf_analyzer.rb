require "pdf-reader"

module Claims
  # Extracts structured data from digitally generated EOB PDFs
  # 
  # This class parses Explanation of Benefits (EOB) documents and extracts:
  # 1. Demographics: Patient name, DOB, Insured, Member ID, ICN
  # 2. Line Items: Service dates, procedure codes, remit/remark codes, amounts
  #
  # Example usage:
  #   analyzer = Claims::PdfAnalyzer.new(file: uploaded_file)
  #   result = analyzer.call
  #   # => { demographics: {...}, line_items: [{...}], ... }
  #
  class PdfAnalyzer
    # Legacy regex for backward compatibility - finds all alphanumeric codes
    DENIAL_CODE_REGEX = /\b[A-Z]{1,2}\d{2,4}\b/
    
    # Remit codes: 2-letter group (CO, PR, OA) + numeric reason
    # Examples: CO29, PR3, OA45
    REMIT_CODE_REGEX = /\b(CO|PR|OA|CR|PI)\s*(\d{1,4})\b/
    
    # Remark codes: Letter N/M followed by numbers
    # Examples: N211, M86, N54
    REMARK_CODE_REGEX = /\b([NM]\d{2,4})\b/

    def initialize(file:)
      @file = file
    end

    # Main extraction method
    # @return [Hash] with keys:
    #   :source => "pdf"
    #   :raw_text => full extracted text
    #   :demographics => { patient_name, dob, insured, member_id, icn }
    #   :line_items => [{ service_date, procedure_code, billed, allowed, 
    #                     remit_codes, remark_codes, paid }]
    #   :denial_codes => legacy flat array of all codes
    def call
      text = extract_text
      
      demographics = extract_demographics(text)
      line_items = extract_line_items(text)
      all_denial_codes = extract_all_denial_codes(text)
    
      payer_name = extract_payer_name(text)
      submitter_name = "ClearClaim Assistant"
      
      {
        source: "pdf",
        raw_text: text,
        demographics: demographics,
        line_items: line_items,
        denial_codes: all_denial_codes,
        # Legacy compatibility fields
        patient_name: demographics[:patient_name],
        claim_number: demographics[:icn],  # ICN is the claim number
        payer_name: payer_name,
        submitter_name: submitter_name,
        service_period: extract_service_period(line_items)
      }
    end

    private

    attr_reader :file

    # Extracts text from all PDF pages
    def extract_text
      reader = PDF::Reader.new(resolved_source)
      reader.pages.map(&:text).join("\n")
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      raise StandardError, "Unable to read PDF: #{e.message}"
    ensure
      temp_file&.close!
    end

    def resolved_source
      return file.path if file.respond_to?(:path)
      temp_file.path
    end

    def temp_file
      return @temp_file if defined?(@temp_file)

      buffer = Tempfile.new(["claim-upload", ".pdf"])
      buffer.binmode
      payload = file.respond_to?(:read) ? file.read : file.to_s
      buffer.write(payload)
      buffer.rewind
      @temp_file = buffer
    end

    # Extracts demographic fields from EOB header section
    # Looks for labeled fields like "Patient:", "DOB:", etc.
    def extract_demographics(text)
      {
        # Capture the value following the label up to the next label on the
        # same line (e.g., "DOB:", "Member ID:") or end-of-line. This avoids
        # leaking adjacent labels into the value when PDFs render multiple
        # header fields on one line.
        patient_name: extract_label_value(text, "Patient"),
        dob: match_value(text, /DOB:\s*([\d\/\-]+)/),
        insured: extract_label_value(text, "Insured"),
        member_id: match_value(text, /Member\s+ID:\s*(\S+)/i),
        icn: match_value(text, /ICN:\s*(\S+)/i)
      }
    end

    # Extracts billing line items from table rows
    # 
    # EOB tables typically have format:
    # Provider# | Date | POS | NOS | Procedure | Billed | Allowed | Deductible | 
    # Co-Insurance | Remit Code | Amount | Remark | Paid
    #
    # Example row:
    # 101111111 11/27/2024 11 1 99215 940.00 0.00 0.00 0.00 CO29 940.00 N211 0.00
    #
    # We extract:
    # - service_date: 11/27/2024
    # - procedure_code: 99215
    # - billed: 940.00
    # - remit_codes: ["CO29"]
    # - remark_codes: ["N211"]
    # - paid: 0.00
    def extract_line_items(text)
      line_items = []
      
      text.each_line do |line|
        # Skip if no date pattern
        next unless line.match?(/\d{1,2}\/\d{1,2}\/\d{4}/)
        
        # Skip if no procedure code
        # Support CPT (five digits, optional trailing letter) and HCPCS (letter + 4 digits)
        next unless line.match?(/\b(?:\d{5}[A-Z]?|[A-Z]\d{4})\b/)
        
        service_date = match_value(line, /(\d{1,2}\/\d{1,2}\/\d{4})/)
        procedure_code = match_value(line, /\b(\d{5}[A-Z]?|[A-Z]\d{4})\b/)
        
        # Extract all dollar amounts (format: ###.##)
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

    # Extracts remit codes (Group Code + Reason Code)
    # Format: 2 letters + digits (CO29, PR3, OA19)
    def extract_remit_codes(text)
      codes = []
      text.scan(REMIT_CODE_REGEX) do |match|
        codes << "#{match[0]}#{match[1]}"
      end
      codes.uniq
    end

    # Extracts remark codes
    # Format: N or M + 2-4 digits (N211, M86)
    def extract_remark_codes(text)
      text.scan(REMARK_CODE_REGEX).flatten.uniq
    end

    # Legacy method - returns all codes as flat array
    def extract_all_denial_codes(text)
      remit = extract_remit_codes(text)
      remark = extract_remark_codes(text)
      (remit + remark).uniq
    end

    # Extracts service period from line items
    def extract_service_period(line_items)
      return nil if line_items.empty?
      
      dates = line_items.map { |item| item[:service_date] }.compact
      return dates.first if dates.size == 1
      
      "#{dates.first} - #{dates.last}"
    end

    # Utility: Extract single value using regex
    def match_value(text, regex)
      match = text.match(regex)
      match ? match[1].strip : nil
    end

    # Extract a labeled value, stopping at the next label on the same line.
    # Example line: "Patient: DOE, DAVE    DOB: 01/29/1964"
    # For label "Patient", this returns "DOE, DAVE".
    def extract_label_value(text, label)
      # Find the first line containing the label
      line = text.each_line.find { |l| l.match?(/\b#{Regexp.escape(label)}:/i) }
      return nil unless line

      # Take everything after the label
      value = line.split(/#{Regexp.escape(label)}:\s*/i, 2)[1].to_s

      # Trim at the start of the next label on the same line: two or more
      # spaces followed by a capitalized word and a colon (e.g., "  DOB:").
      value = value.split(/\s{2,}[A-Z][A-Za-z\s\/#-]*:/, 2)[0].to_s

      value.strip.presence
    end

      # Add method to extract payer name (insurance company)
    def extract_payer_name(text)
      # Look for insurance company name at the top of the document
      # Pattern 1: First line that looks like a company name
      first_lines = text.split("\n").first(5)
      company_line = first_lines.find { |line| line.match?(/INSURANCE|HEALTH|MEDICAL|CARE/) }
      return company_line.strip if company_line
      
      # Pattern 2: Explicit payer field
      payer_match = text.match(/Payer:\s*(.+?)(?:\s{2,}|\n)/i)
      payer_match[1].strip if payer_match
    end

    # Add method to extract submitter/provider name
    # Deprecated: submitter is now fixed to "ClearClaim Assistant".

    # Update service period extraction to handle single dates
    def extract_service_period(line_items)
      return nil if line_items.empty?
      
      dates = line_items.map { |item| item[:service_date] }.compact.uniq.sort
      return dates.first if dates.size == 1
      
      "#{dates.first} - #{dates.last}"
    end
  end
end
