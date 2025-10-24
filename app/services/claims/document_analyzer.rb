module Claims
  # Determines whether to parse via PDF reader or OCR fallback
  class DocumentAnalyzer
    def initialize(file:)
      @file = file
    end

    def call
      raise ArgumentError, "file is required" unless file

      if pdf_file?
        PdfAnalyzer.new(file: file).call
      else
        OcrReader.new(file: file).call
      end
    end

    private

    attr_reader :file

    def pdf_file?
      return false unless file.respond_to?(:content_type) || file.respond_to?(:original_filename)

      type = file.respond_to?(:content_type) ? file.content_type : nil
      name = file.respond_to?(:original_filename) ? file.original_filename : nil
      return true if type&.downcase == "application/pdf"
      return true if name&.downcase&.end_with?(".pdf")

      false
    end
  end
end
