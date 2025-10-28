Given("a denial rule exists with EOB code {string}, group code {string}, reason code {string}, and description {string}") do |code, group_code, reason_code, description|
  create(
    :denial_reason,
    code: code,
    group_code: group_code,
    reason_codes: reason_code.present? ? [reason_code] : [],
    description: description
  )
end

When("I request corrections for the following tuples:") do |table|
  tuples = table.hashes.map do |row|
    remit = row["remit_code"]
    remark = row["remark_code"]
    [remit, remark.present? ? remark : nil]
  end

  payload = { denial_codes: tuples }
  page.driver.post("/claims/suggest_corrections", payload.to_json, { "CONTENT_TYPE" => "application/json" })
  @api_response = JSON.parse(page.driver.response.body)
end

Then("the API response should include a correction with code {string} and reason code {string}") do |code, reason_code|
  expect(@api_response).to be_present
  suggestion = @api_response.fetch("suggestions").find do |entry|
    entry["code"] == code && entry["reason_code"] == reason_code
  end
  expect(suggestion).to be_present
end
