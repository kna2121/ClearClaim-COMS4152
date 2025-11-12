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
        raise ArgumentError, "Only PDF files are supported"
      end
    end

    private

    attr_reader :file

    def pdf_file?
      # 1) Content-Type says PDF
      if file.respond_to?(:content_type)
        type = file.content_type.to_s.downcase
        return true if type == "application/pdf"
      end

      # 2) Uploaded filename indicates PDF
      if file.respond_to?(:original_filename)
        name = file.original_filename.to_s.downcase
        return true if name.end_with?(".pdf")
      end

      # 3) Local file path indicates PDF
      if file.respond_to?(:path)
        path = file.path.to_s.downcase
        return true if path.end_with?(".pdf")
      end

      # 4) Magic header sniff: starts with %PDF-
      if file.respond_to?(:read)
        begin
          # Peek the first 5 bytes, then rewind to not disturb readers
          head = file.read(5)
          file.rewind if file.respond_to?(:rewind)
          return true if head.to_s.start_with?("%PDF-")
        rescue StandardError
          # Ignore sniffing errors and fall back to non-PDF
        end
      end

      false
    end
  end
end
