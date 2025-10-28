# Cucumber Step Definitions for EOB PDF Analysis
#
# These implement the Given/When/Then steps from the feature file
#
# Ruby/Cucumber Concepts:
# - Step definitions use regex to match feature file steps
# - |table| parameter captures data tables from feature files
# - @variable: instance variables persist across steps in a scenario
# - World: shared context between steps (like 'this' in JavaScript)

require 'tempfile'
require 'prawn'

# Background step
Given('the system is configured to analyze EOB documents') do
  # This is a setup step - ensure Rails environment is ready
  expect(Rails.application).to be_present
  expect(Claims::DocumentAnalyzer).to be_present
end

# Scenario 1: Demographics Extraction Steps

Given('I have an EOB PDF with the following patient information:') do |table|
  # Store the expected data for later verification
  @expected_demographics = table.hashes.each_with_object({}) do |row, hash|
    hash[row['Field'].downcase.tr(' ', '_')] = row['Value']
  end
  
  # Create a test PDF with this data
  @test_pdf_path = create_test_eob_pdf(demographics: @expected_demographics)
end

When('I upload the PDF for analysis') do
  # Open the PDF file and analyze it
  File.open(@test_pdf_path, 'rb') do |file|
    analyzer = Claims::DocumentAnalyzer.new(file: file)
    @analysis_result = analyzer.call
  end
end

Then('the system should extract the following demographics:') do |table|
  # Verify each demographic field was extracted correctly
  table.hashes.each do |row|
    field = row['Field'].to_sym
    expected_value = row['Value']
    actual_value = @analysis_result[:demographics][field]
    
    expect(actual_value).to eq(expected_value),
      "Expected #{field} to be '#{expected_value}', got '#{actual_value}'"
  end
end

# Scenario 2: Line Items Extraction Steps

Given('I have an EOB PDF with the following line items:') do |table|
  # Store line items and create test PDF
  @expected_line_items = table.hashes
  @test_pdf_path = create_test_eob_pdf(line_items: @expected_line_items)
end

Then('the system should extract {int} line items') do |expected_count|
  actual_count = @analysis_result[:line_items].size
  expect(actual_count).to eq(expected_count),
    "Expected #{expected_count} line items, got #{actual_count}"
end

Then('line item {int} should have:') do |line_number, table|
  # Arrays are 0-indexed, so line_number 1 is index 0
  line_item = @analysis_result[:line_items][line_number - 1]
  
  expect(line_item).to be_present, "Line item #{line_number} not found"
  
  table.hashes.each do |row|
    field = row['Field'].to_sym
    expected_value = row['Value']
    
    # Convert to appropriate type
    actual_value = line_item[field]
    if field.to_s.include?('date')
      expected_value = expected_value.to_s
    elsif field.to_s == 'billed'
      expected_value = expected_value.to_f
    end
    
    expect(actual_value).to eq(expected_value),
      "Expected #{field} to be '#{expected_value}', got '#{actual_value}'"
  end
end

Then('line item {int} should have remit code {string}') do |line_number, code|
  line_item = @analysis_result[:line_items][line_number - 1]
  expect(line_item[:remit_codes]).to include(code),
    "Expected remit codes to include '#{code}', got #{line_item[:remit_codes]}"
end

Then('line item {int} should have remark code {string}') do |line_number, code|
  line_item = @analysis_result[:line_items][line_number - 1]
  expect(line_item[:remark_codes]).to include(code),
    "Expected remark codes to include '#{code}', got #{line_item[:remark_codes]}"
end

# Scenario 3: Code Type Separation Steps

Given('I have an EOB PDF with denial codes {string}, {string}, {string}, and {string}') do |code1, code2, code3, code4|
  @test_codes = [code1, code2, code3, code4]
  
  # Create PDF with these codes embedded
  @test_pdf_path = create_test_eob_pdf(
    line_items: [{
      'Service Date' => '11/27/2024',
      'Procedure' => '99215',
      'Billed' => '100.00',
      'Remit Code' => "#{code1} #{code2}",
      'Remark Code' => "#{code3} #{code4}"
    }]
  )
end

Then('the remit codes should include:') do |table|
  expected_codes = table.hashes.map { |row| row['Code'] }
  
  # Get all remit codes from all line items
  all_remit_codes = @analysis_result[:line_items].flat_map { |item| item[:remit_codes] }
  
  expected_codes.each do |code|
    expect(all_remit_codes).to include(code),
      "Expected remit codes to include '#{code}', got #{all_remit_codes}"
  end
end

Then('the remark codes should include:') do |table|
  expected_codes = table.hashes.map { |row| row['Code'] }
  
  # Get all remark codes from all line items
  all_remark_codes = @analysis_result[:line_items].flat_map { |item| item[:remark_codes] }
  
  expected_codes.each do |code|
    expect(all_remark_codes).to include(code),
      "Expected remark codes to include '#{code}', got #{all_remark_codes}"
  end
end

# Scenario 4: Multi-page Steps

Given('I have a {int}-page EOB PDF with line items on each page') do |page_count|
  # Create multi-page PDF
  @test_pdf_path = create_multipage_eob_pdf(pages: page_count)
end

Then('the system should extract line items from all pages') do
  expect(@analysis_result[:line_items].size).to be >= 3,
    "Expected at least 3 line items from multi-page PDF"
end

Then('all line items should have valid service dates') do
  @analysis_result[:line_items].each do |item|
    expect(item[:service_date]).to match(/\d{1,2}\/\d{1,2}\/\d{4}/),
      "Invalid date format: #{item[:service_date]}"
  end
end

# Scenario 5: Error Handling Steps

Given('I have a corrupted PDF file') do
  @test_pdf_path = Tempfile.new(['corrupted', '.pdf']).path
  File.write(@test_pdf_path, "This is not a valid PDF")
end

When('I attempt to upload it for analysis') do
  begin
    File.open(@test_pdf_path, 'rb') do |file|
      analyzer = Claims::DocumentAnalyzer.new(file: file)
      analyzer.call
    end
    @error = nil
  rescue StandardError => e
    @error = e
  end
end

Then('I should receive an error message {string}') do |expected_message|
  expect(@error).to be_present, "Expected an error but none was raised"
  expect(@error.message).to include(expected_message)
end

Then('the error should be user-friendly') do
  expect(@error.message).not_to include('backtrace')
  expect(@error.message.length).to be < 200
end

# Scenario 6: Missing Fields Steps

Given('I have an EOB PDF with patient name but no DOB') do
  @test_pdf_path = create_test_eob_pdf(
    demographics: { 'patient' => 'SMITH, JOHN' },
    skip_dob: true
  )
end

Then('the patient_name should be extracted') do
  expect(@analysis_result[:demographics][:patient_name]).to be_present
end

Then('the dob should be nil') do
  expect(@analysis_result[:demographics][:dob]).to be_nil
end

Then('the system should not fail') do
  expect(@analysis_result).to be_present
  expect(@error).to be_nil
end

# Scenario 7: API Integration Steps

Given('I have a valid EOB PDF file') do
  @test_pdf_path = create_test_eob_pdf
end

When('I POST the file to {string}') do |endpoint|
  # Use Capybara to make HTTP POST request
  file = Rack::Test::UploadedFile.new(@test_pdf_path, 'application/pdf')
  page.driver.post(endpoint, { file: file })
  @api_response = JSON.parse(page.driver.response.body)
  @api_status = page.driver.response.status
end

Then('the response status should be {int}') do |expected_status|
  expect(@api_status).to eq(expected_status)
end

Then('the response should contain {string}') do |field|
  expect(@api_response['claim']).to have_key(field),
    "Expected response to contain '#{field}', got keys: #{@api_response['claim'].keys}"
end

# Scenario 8: Backward Compatibility Steps

Given('I have an EOB PDF') do
  @test_pdf_path = create_test_eob_pdf
end

Then('the response should include legacy fields:') do |table|
  expected_fields = table.hashes.map { |row| row['Field'] }
  
  expected_fields.each do |field|
    expect(@analysis_result).to have_key(field.to_sym),
      "Expected response to include legacy field '#{field}'"
  end
end

Then('the {string} field should be a flat array') do |field|
  value = @analysis_result[field.to_sym]
  expect(value).to be_an(Array)
  expect(value.all? { |item| item.is_a?(String) }).to be true
end

Then('the {string} should equal the ICN value') do |field|
  claim_number = @analysis_result[field.to_sym]
  icn = @analysis_result[:demographics][:icn]
  expect(claim_number).to eq(icn)
end

# Helper Methods
# These create test PDF files with specified content

def create_test_eob_pdf(demographics: {}, line_items: [], skip_dob: false)
  pdf_path = Tempfile.new(['test_eob', '.pdf']).path
  
  # Default demographics
  demo = {
    'patient' => 'DOE, DAVE',
    'dob' => '01/29/1964',
    'insured' => 'DOE, DAVE',
    'member_id' => 'ABC123EFG',
    'icn' => '202303EF123'
  }.merge(demographics)
  
  # Default line items if none provided
  if line_items.empty?
    line_items = [{
      'Service Date' => '11/27/2024',
      'Procedure' => '99215',
      'Billed' => '940.00',
      'Remit Code' => 'CO29',
      'Remark Code' => 'N211'
    }]
  end
  
  # Build PDF content
  Prawn::Document.generate(pdf_path) do
    text "ABC INSURANCE COMPANY", size: 16, style: :bold
    text "REMITTANCE ADVICE"
    move_down 20
    
    # Demographics section
    text "Patient: #{demo['patient']}"
    text "DOB: #{demo['dob']}" unless skip_dob
    text "Insured: #{demo['insured']}"
    text "Member ID: #{demo['member_id']}"
    text "ICN: #{demo['icn']}"
    move_down 20
    
    # Line items section
    text "Service Details:", style: :bold
    line_items.each do |item|
      text "#{item['Service Date']} | #{item['Procedure']} | $#{item['Billed']} | #{item['Remit Code']} | #{item['Remark Code']}"
    end
  end
  
  pdf_path
end

def create_multipage_eob_pdf(pages: 3)
  pdf_path = Tempfile.new(['multipage_eob', '.pdf']).path
  
  Prawn::Document.generate(pdf_path) do
    pages.times do |page_num|
      text "Page #{page_num + 1}", size: 20
      text "11/27/2024 | 9921#{page_num} | $100.00 | CO29 | N211"
      start_new_page unless page_num == pages - 1
    end
  end
  
  pdf_path
end

# Cleanup after scenarios
After do
  # Clean up temp files
  [@test_pdf_path].compact.each do |path|
    File.delete(path) if path && File.exist?(path)
  end
end