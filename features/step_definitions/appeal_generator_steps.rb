Given('a sample claim with claim number {string} and patient {string}') do |claim_number, name|
  @claim = {
    claim_number: claim_number,
    patient_name: name,
    payer_name: 'Acme Health',
    service_period: '2025-01-01',
    submitter_name: 'ClearClaim Assistant'
  }
end

Given('denial reasons list:') do |table|
  @denial_reasons = table.hashes.map { |h| h.symbolize_keys }
end

When('I generate an appeal via the service') do
  @appeal_result = Appeals::AppealGenerator.new(
    claim: @claim,
    denial_reasons: @denial_reasons
  ).call
end

Then('the appeal letter should include {string}') do |snippet|
  expect(@appeal_result).to be_a(Hash)
  expect(@appeal_result[:appeal_letter]).to include(snippet)
end

Given('ERB rendering will raise {string}') do |message|
  allow(ERB).to receive(:new).and_raise(StandardError, message)
end

Then('I should receive an appeal generation error containing {string}') do |message|
  expect(@appeal_result[:error]).to include(message)
end

Given('I force generator to use remote LLM with mocked reply {string}') do |reply|
  # Pretend we are not in test env for this scenario and ensure ENV keys exist
  allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
  allow_any_instance_of(Appeals::AppealGenerator).to receive(:query_llm).and_return(reply)
  # Provide fake API key to bypass the local-template shortcut
  @orig_api_key = ENV['OPENAI_API_KEY']
  ENV['OPENAI_API_KEY'] = 'fake'
end

After do
  # Restore any env changes if present
  ENV['OPENAI_API_KEY'] = @orig_api_key if defined?(@orig_api_key)
end

