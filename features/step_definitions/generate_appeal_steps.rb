
Given('a denial claim with claim number {string} and name {string}') do |claim_number, name|
    @claim = {
        claim_number: claim_number,
        patient_name: name,
        payer_name: "United Healthcare",
        service_period: "2025-01-10",
        submitter_name: "Dr. Lee"
    }
end

Given("the denial reasons are:") do |table|
    @denial_codes = table.hashes
end

When("I request to generate an appeal letter") do
    payload = {
        claim: @claim,
        denial_codes: @denial_codes
    }
    post(
        "/claims/generate_appeal",
        payload.to_json,
        { "CONTENT_TYPE" => "application/json" }
    )
    @response = last_response
end

Then("I should receive a successful response") do
    expect(@response.status).to eq(200)
end

Then("the response should include the patient name {string}.") do |name|
    expect(@response.body).to include(name)
end