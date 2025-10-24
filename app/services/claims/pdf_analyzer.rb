require "pdf-reader"

module Claims
  # Extracts structured data from digitally generated PDFs
  class PdfAnalyzer
    DENIAL_CODE_REGEX = /\b[A-Z]{1,2}\d{2,4}\b/

    def initialize(file:)
      @file = file
    end

    def call
      text = extract_text
      {
        source: "pdf",
        raw_text: text,
        claim_number: match_value(text, /Claim\s*#?:\s*(\S+)/i),
        patient_name: match_value(text, /Patient:\s*([A-Za-z ,.'-]+)/i),
        denial_codes: text.scan(DENIAL_CODE_REGEX).uniq,
        service_period: match_value(text, /Service Dates?:\s*([A-Za-z0-9\-\s]+)/i)
      }
    end

    private

    attr_reader :file

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

    def match_value(text, regex)
      match = text.match(regex)
      match ? match[1].strip : nil
    end
  end
end
