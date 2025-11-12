require 'prawn'

def build_valid_pdf_bytes
  pdf = Prawn::Document.new
  pdf.text "ABC INSURANCE COMPANY", size: 16, style: :bold
  pdf.text "Patient: DOE, DAVE"
  pdf.text "DOB: 01/29/1964"
  pdf.text "ICN: 202303EF123"
  pdf.text "11/27/2024 | 99215 | $940.00 | CO29 | N211"
  pdf.render # returns String bytes
end

Given('I have a valid PDF in memory') do
  @pdf_bytes = build_valid_pdf_bytes
end

Given('I have a valid PDF file on disk') do
  @temp_pdf_path = Tempfile.new(['cuke_da', '.pdf']).path
  File.binwrite(@temp_pdf_path, build_valid_pdf_bytes)
end

When('I analyze a non-PDF IO object') do
  # Looks like a PNG and not a PDF
  fake_png = StringIO.new("\x89PNG\x0d\x0a\x1a\x0a some png data")
  begin
    @da_result = Claims::DocumentAnalyzer.new(file: fake_png).call
    @da_error = nil
  rescue => e
    @da_error = e
  end
end

When('I call DocumentAnalyzer with no file') do
  begin
    Claims::DocumentAnalyzer.new(file: nil).call
    @da_error = nil
  rescue => e
    @da_error = e
  end
end

# Alias matchers to avoid minor wording mismatches in the step text
When(/^I analyze with content[_ ]type set to application\/pdf$/) do
  # Build an IO that responds to content_type and read
  io = StringIO.new(@pdf_bytes)
  def io.content_type; 'application/pdf'; end
  begin
    @da_result = Claims::DocumentAnalyzer.new(file: io).call
    @da_error = nil
  rescue => e
    @da_error = e
  end
end

When('I analyze with original_filename ending in .pdf') do
  io = StringIO.new(@pdf_bytes)
  def io.original_filename; 'test_document.pdf'; end
  begin
    @da_result = Claims::DocumentAnalyzer.new(file: io).call
    @da_error = nil
  rescue => e
    @da_error = e
  end
end

When('I analyze it via File path') do
  File.open(@temp_pdf_path, 'rb') do |file|
    begin
      @da_result = Claims::DocumentAnalyzer.new(file: file).call
      @da_error = nil
    rescue => e
      @da_error = e
    end
  end
end

When('I analyze a stream that starts with the PDF header') do
  # Use a real PDF byte string so downstream PdfAnalyzer can parse it
  io = StringIO.new(@pdf_bytes)
  begin
    @da_result = Claims::DocumentAnalyzer.new(file: io).call
    @da_error = nil
  rescue => e
    @da_error = e
  end
end

Then('the analyzer should route to PdfAnalyzer') do
  expect(@da_error).to be_nil
  expect(@da_result).to be_a(Hash)
  expect(@da_result[:source]).to eq('pdf')
end

Then('I should receive a DocumentAnalyzer error {string}') do |message|
  expect(@da_error).to be_present
  expect(@da_error.message).to include(message)
end

After do
  FileUtils.rm_f(@temp_pdf_path) if defined?(@temp_pdf_path) && @temp_pdf_path.present?
end
