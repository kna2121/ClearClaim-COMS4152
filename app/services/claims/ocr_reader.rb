require "rtesseract"

module Claims
  # Fallback OCR pathway for scanned denial letters
  class OcrReader
    def initialize(file:)
      @file = file
    end

    def call
      text = extract_text
      {
        source: "ocr",
        raw_text: text,
        denial_codes: text.scan(PdfAnalyzer::DENIAL_CODE_REGEX).uniq
      }
    end

    private

    attr_reader :file

    def extract_text
      path = resolve_path
      RTesseract.new(path).to_s
    ensure
      temp_file&.close!
    end

    def resolve_path
      return file.path if file.respond_to?(:path)

      temp_file.path
    end

    def temp_file
      return @temp_file if defined?(@temp_file)

      buffer = Tempfile.new(["claim-ocr", ".png"])
      payload = file.respond_to?(:read) ? file.read : file.to_s
      buffer.binmode
      buffer.write(payload)
      buffer.rewind
      @temp_file = buffer
    end
  end
end
