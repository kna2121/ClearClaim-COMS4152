require "rails_helper"

RSpec.describe "Appeals", type: :request do
  it "generates an appeal letter" do
    post "/claims/generate_appeal", params: {
      claim: {
        claim_number: "A123",
        patient_name: "John Doe",
        payer_name: "Aetna",
        service_period: "2025-01-10"
      },
      denial_codes: [{ code: "CO197", reason: "Missing pre-authorization" }]
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["appeal_letter"]).to include("Aetna")
  end
end
