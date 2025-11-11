Given('I have an EOB PDF with complete information:') do |table|
  # Convert 2-column Field/Value table to a hash
  rows = table.raw.dup
  # Drop header if present
  if rows.first && rows.first.map(&:to_s).map(&:strip).map(&:downcase) == ["field", "value"]
    rows.shift
  end
  @eob_data = rows.to_h { |k, v| [k.to_s.strip, v] }

  pdf_path = Tempfile.new(['complete_eob', '.pdf']).path
  require 'prawn'
  data = @eob_data
  Prawn::Document.generate(pdf_path) do
    text(data['Payer'] || '')
    text "REMITTANCE ADVICE"
    text "Patient: #{data['Patient']}"
    text "ICN: #{data['ICN']}"
    text "Provider: #{data['Provider']}"
    text "#{data['Service Date']} | 99215 | 940.00 | #{data['Remit Code']} | #{data['Remark Code']}"
  end

  @test_pdf_path = pdf_path
end

Then('the analysis should include:') do |table|
  table.hashes.each do |row|
    field = row['Field']
    value = row['Value']
    expect(@analysis_result[field.to_sym]).to eq(value)
  end
end

Given('I have analyzed an EOB PDF') do
  @analyzed_claim = {
    claim_number: "202303EF123",
    patient_name: "DOE, DAVE",
    payer_name: "ABC INSURANCE COMPANY",
    service_period: "11/27/2024",
    submitter_name: "ClearClaim Assistant"
  }
end

When('I request to generate an appeal') do
  payload = {
    claim: @analyzed_claim,
    denial_codes: ["CO29", "N211"]
  }
  
  post "/claims/generate_appeal", payload.to_json, 
       { "CONTENT_TYPE" => "application/json" }
  
  @appeal_response = JSON.parse(last_response.body)
end

Then('the appeal should reference the correct claim number') do
  expect(@appeal_response['appeal_letter']).to include("202303EF123")
end

Then('the appeal should include the patient name') do
  expect(@appeal_response['appeal_letter']).to include("DOE, DAVE")
end

Then('the appeal should address the insurance company') do
  expect(@appeal_response['appeal_letter']).to include("ABC INSURANCE COMPANY")
end

# Additional assertions for codes across any line item
Then('the line items should contain remit code {string}') do |code|
  all_remit = Array(@analysis_result[:line_items]).flat_map { |li| Array(li[:remit_codes]) }
  expect(all_remit).to include(code)
end

Then('the line items should contain remark code {string}') do |code|
  all_remark = Array(@analysis_result[:line_items]).flat_map { |li| Array(li[:remark_codes]) }
  expect(all_remark).to include(code)
end
